package com.ridersclub.friend.service;

import com.ridersclub.friend.dto.response.FriendDto;
import com.ridersclub.friend.dto.response.FriendRelationshipDto;
import com.ridersclub.friend.dto.response.PendingRequestDto;
import com.ridersclub.friend.entity.FriendRequest;
import com.ridersclub.friend.entity.Friendship;
import com.ridersclub.friend.enums.FriendRequestStatus;
import com.ridersclub.friend.repository.FriendRequestRepository;
import com.ridersclub.friend.repository.FriendshipRepository;
import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.neo4j.core.Neo4jClient;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.cache.CacheManager;
import org.springframework.cache.Cache;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class FriendService {

    private static final String MUTUAL_COUNT_CYPHER =
            "MATCH (u1:User {id: $id1})-[:FRIENDS_WITH]-(f:User)-[:FRIENDS_WITH]-(u2:User {id: $id2}) "
                    + "RETURN count(DISTINCT f)";
    private static final String LOG_PREFIX = "FRIEND_SERVICE";

    private final FriendRequestRepository friendRequestRepository;
    private final FriendshipRepository friendshipRepository;
    private final UserRepository userRepository;
    private final FriendshipEventPublisher friendshipEventPublisher;
    private final SimpMessagingTemplate messagingTemplate;
    private final Neo4jClient neo4jClient;
    private final NotificationService notificationService;
    private final CacheManager cacheManager;

    private void notifyUsersAfterCommit(String... uuids) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    for (String uuid : uuids) {
                        notifyUser(uuid);
                    }
                }
            });
        } else {
            for (String uuid : uuids) {
                notifyUser(uuid);
            }
        }
    }

    private void evictAndNotifyAfterCommit(String... uuids) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    Cache cache = cacheManager.getCache("user_friends");
                    for (String uuid : uuids) {
                        log.debug("{} action=evict_and_notify_after_commit user={}", LOG_PREFIX, uuid);
                        if (cache != null) {
                            cache.evict(uuid);
                        }
                        notifyUser(uuid);
                    }
                }
            });
        } else {
            Cache cache = cacheManager.getCache("user_friends");
            for (String uuid : uuids) {
                log.debug("{} action=evict_and_notify_no_tx user={}", LOG_PREFIX, uuid);
                if (cache != null) {
                    cache.evict(uuid);
                }
                notifyUser(uuid);
            }
        }
    }

    private User getRequiredUser(String userUuid, String label) {
        return userRepository.findByUuid(userUuid)
                .orElseThrow(() -> new IllegalArgumentException(label + " not found"));
    }

    private FriendRequest getAuthorizedPendingRequest(String receiverUuid, Long requestId, String action) {
        FriendRequest request = friendRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Friend request not found"));

        if (!request.getReceiver().getUuid().equals(receiverUuid)) {
            log.warn("{} action={}_blocked reason=unauthorized receiver={} requestId={}", LOG_PREFIX, action,
                    receiverUuid, requestId);
            throw new SecurityException("Not authorized to " + action.replace('_', ' ') + " this request");
        }

        if (request.getStatus() != FriendRequestStatus.PENDING) {
            log.warn("{} action={}_blocked reason=not_pending requestId={} status={}", LOG_PREFIX, action, requestId,
                    request.getStatus());
            throw new IllegalArgumentException("Friend request is not pending");
        }

        return request;
    }

    private Friendship buildFriendship(User user, User friend) {
        Friendship friendship = new Friendship();
        friendship.setUser(user);
        friendship.setFriend(friend);
        return friendship;
    }

    private void notifyUser(String userUuid) {
        try {
            messagingTemplate.convertAndSend("/topic/friends/" + userUuid, "{\"action\":\"REFRESH\"}");
            log.debug("{} action=push_refresh target={}", LOG_PREFIX, userUuid);
        } catch (Exception e) {
            log.warn("{} action=push_refresh_failed target={} reason={}", LOG_PREFIX, userUuid, e.getMessage());
        }
    }

    private int queryMutualCount(String uuid1, String uuid2) {
        try {
            return neo4jClient.query(MUTUAL_COUNT_CYPHER)
                    .bind(uuid1).to("id1")
                    .bind(uuid2).to("id2")
                    .fetchAs(Long.class).one().orElse(0L).intValue();
        } catch (Exception e) {
            log.warn("{} action=query_mutual_count_failed user1={} user2={} reason={}", LOG_PREFIX, uuid1, uuid2,
                    e.getMessage());
            return 0;
        }
    }

    @Transactional
    public void sendRequest(String senderUuid, String receiverUuid) {
        log.info("{} action=send_request_start sender={} receiver={}", LOG_PREFIX, senderUuid, receiverUuid);
        if (senderUuid.equals(receiverUuid)) {
            log.warn("{} action=send_request_blocked reason=self_request sender={}", LOG_PREFIX, senderUuid);
            throw new IllegalArgumentException("Cannot send a friend request to yourself");
        }

        User sender = getRequiredUser(senderUuid, "Sender");
        User receiver = getRequiredUser(receiverUuid, "Receiver");

        if (friendshipRepository.existsByUserAndFriend(sender, receiver)) {
            log.warn("{} action=send_request_blocked reason=already_friends sender={} receiver={}", LOG_PREFIX,
                    senderUuid, receiverUuid);
            throw new IllegalArgumentException("Users are already friends");
        }

        if (friendRequestRepository.existsBySenderAndReceiverAndStatus(sender, receiver, FriendRequestStatus.PENDING)
                || friendRequestRepository.existsBySenderAndReceiverAndStatus(receiver, sender,
                        FriendRequestStatus.PENDING)) {
            log.warn("{} action=send_request_blocked reason=pending_exists sender={} receiver={}", LOG_PREFIX,
                    senderUuid, receiverUuid);
            throw new IllegalArgumentException("Pending friend request already exists between these users");
        }

        var existingOutgoingRequest = friendRequestRepository.findBySenderAndReceiver(sender, receiver);
        if (existingOutgoingRequest.isPresent()) {
            FriendRequest request = existingOutgoingRequest.get();
            reactivateRequest(request, sender, receiver, "outgoing");
            notifyUsersAfterCommit(senderUuid, receiverUuid);
            return;
        }

        var existingIncomingRequest = friendRequestRepository.findBySenderAndReceiver(receiver, sender);
        if (existingIncomingRequest.isPresent()) {
            FriendRequest request = existingIncomingRequest.get();
            reactivateRequest(request, sender, receiver, "incoming");
            notifyUsersAfterCommit(senderUuid, receiverUuid);
            return;
        }

        FriendRequest request = new FriendRequest();
        request.setSender(sender);
        request.setReceiver(receiver);
        friendRequestRepository.save(request);
        log.info("{} action=send_request_created sender={} receiver={} requestId={}", LOG_PREFIX, senderUuid,
                receiverUuid, request.getId());
        createFriendRequestNotification(sender, receiver, request.getId());
        notifyUsersAfterCommit(senderUuid, receiverUuid);
    }

    private void reactivateRequest(FriendRequest request, User sender, User receiver, String direction) {
        FriendRequestStatus previousStatus = request.getStatus();
        request.setSender(sender);
        request.setReceiver(receiver);
        request.setStatus(FriendRequestStatus.PENDING);
        request.setCreatedAt(java.time.LocalDateTime.now());
        friendRequestRepository.save(request);
        createFriendRequestNotification(sender, receiver, request.getId());
        log.info(
                "{} action=send_request_reactivated requestId={} previousStatus={} direction={} sender={} receiver={}",
                LOG_PREFIX,
                request.getId(),
                previousStatus,
                direction,
                sender.getUuid(),
                receiver.getUuid());
    }

    private void createFriendRequestNotification(User sender, User receiver, Long requestId) {
        String senderName = ((sender.getFirstName() == null ? "" : sender.getFirstName()) + " "
                + (sender.getLastName() == null ? "" : sender.getLastName())).trim();
        if (senderName.isEmpty()) {
            senderName = "Someone";
        }

        notificationService.createAndSend(
                receiver.getId(),
                NotificationType.FRIEND_REQUEST,
                "New Friend Request",
                senderName + " sent you a friend request.",
                requestId,
                "FRIEND_REQUEST");
        log.info("{} action=create_request_notification sender={} receiver={}", LOG_PREFIX, sender.getUuid(),
                receiver.getUuid());
    }

    @Transactional
    public void acceptRequest(String receiverUuid, Long requestId) {
        log.info("{} action=accept_request_start receiver={} requestId={}", LOG_PREFIX, receiverUuid, requestId);
        FriendRequest request = getAuthorizedPendingRequest(receiverUuid, requestId, "accept_request");

        request.setStatus(FriendRequestStatus.ACCEPTED);
        friendRequestRepository.save(request);

        User sender = request.getSender();
        User receiver = request.getReceiver();

        String receiverName = ((receiver.getFirstName() == null ? "" : receiver.getFirstName()) + " "
                + (receiver.getLastName() == null ? "" : receiver.getLastName())).trim();
        if (receiverName.isEmpty()) {
            receiverName = "your friend";
        }

        List<Friendship> friendshipsToCreate = new ArrayList<>();
        if (!friendshipRepository.existsByUserAndFriend(sender, receiver)) {
            friendshipsToCreate.add(buildFriendship(sender, receiver));
        }

        if (!friendshipRepository.existsByUserAndFriend(receiver, sender)) {
            friendshipsToCreate.add(buildFriendship(receiver, sender));
        }

        if (!friendshipsToCreate.isEmpty()) {
            friendshipRepository.saveAll(friendshipsToCreate);
            log.info("{} action=friendship_persisted sender={} receiver={} requestId={} createdLinks={}", LOG_PREFIX,
                    sender.getUuid(), receiver.getUuid(), requestId, friendshipsToCreate.size());
        } else {
            log.warn("{} action=friendship_already_present sender={} receiver={} requestId={}", LOG_PREFIX,
                    sender.getUuid(), receiver.getUuid(), requestId);
        }

        notificationService.createAndSend(
                sender.getId(),
                com.ridersclub.common.enums.NotificationType.FRIEND_ACCEPTED,
                "Friend Request Accepted!",
                receiverName + " accepted your friend request.",
                receiver.getId(),
                "USER");

        log.info("{} action=create_accept_notification sender={} receiver={} requestId={}", LOG_PREFIX,
                sender.getUuid(), receiver.getUuid(), requestId);

        friendshipEventPublisher.publishFriendAcceptedEvent(sender.getUuid(), receiver.getUuid());

        evictAndNotifyAfterCommit(sender.getUuid(), receiver.getUuid());

        final String sUuid = sender.getUuid();
        final String sFirst = sender.getFirstName();
        final String sLast = sender.getLastName();
        final String rUuid = receiver.getUuid();
        final String rFirst = receiver.getFirstName();
        final String rLast = receiver.getLastName();

        CompletableFuture.runAsync(() -> {
            try {
                neo4jClient.query(
                        "MERGE (u1:User {id: $id1}) SET u1.firstName = $f1, u1.lastName = $l1 "
                                + "MERGE (u2:User {id: $id2}) SET u2.firstName = $f2, u2.lastName = $l2 "
                                + "MERGE (u1)-[:FRIENDS_WITH]-(u2)")
                        .bind(sUuid).to("id1")
                        .bind(sFirst != null ? sFirst : "").to("f1")
                        .bind(sLast != null ? sLast : "").to("l1")
                        .bind(rUuid).to("id2")
                        .bind(rFirst != null ? rFirst : "").to("f2")
                        .bind(rLast != null ? rLast : "").to("l2")
                        .run();
                log.info("{} action=neo4j_create_completed sender={} receiver={}", LOG_PREFIX, sUuid, rUuid);
            } catch (Exception e) {
                log.error("{} action=neo4j_create_failed sender={} receiver={} reason={}", LOG_PREFIX, sUuid, rUuid,
                        e.getMessage());
            }
        });
    }

    @Transactional
    public void rejectRequest(String receiverUuid, Long requestId) {
        log.info("{} action=reject_request_start receiver={} requestId={}", LOG_PREFIX, receiverUuid, requestId);
        FriendRequest request = getAuthorizedPendingRequest(receiverUuid, requestId, "reject_request");

        request.setStatus(FriendRequestStatus.REJECTED);
        friendRequestRepository.save(request);
        log.info("{} action=reject_request_completed receiver={} requestId={}", LOG_PREFIX, receiverUuid, requestId);
        notifyUsersAfterCommit(receiverUuid, request.getSender().getUuid());
    }

    @Transactional
    public void unfriend(String userUuid, String targetUserUuid) {
        log.info("{} action=unfriend_start user={} target={}", LOG_PREFIX, userUuid, targetUserUuid);
        User user = getRequiredUser(userUuid, "User");
        User target = getRequiredUser(targetUserUuid, "Target user");

        if (!friendshipRepository.existsByUserAndFriend(user, target)) {
            log.warn("{} action=unfriend_blocked reason=not_friends user={} target={}", LOG_PREFIX, userUuid,
                    targetUserUuid);
            throw new IllegalArgumentException("Users are not friends");
        }

        friendshipRepository.deleteByUserAndFriend(user, target);
        friendshipRepository.deleteByUserAndFriend(target, user);
        log.info("{} action=unfriend_completed user={} target={}", LOG_PREFIX, userUuid, targetUserUuid);

        evictAndNotifyAfterCommit(userUuid, targetUserUuid);

        CompletableFuture.runAsync(() -> {
            try {
                neo4jClient.query(
                        "MATCH (u1:User {id: $id1})-[r:FRIENDS_WITH]-(u2:User {id: $id2}) DELETE r")
                        .bind(userUuid).to("id1")
                        .bind(targetUserUuid).to("id2")
                        .run();
                log.info("{} action=neo4j_remove_completed user={} target={}", LOG_PREFIX, userUuid, targetUserUuid);
            } catch (Exception e) {
                log.error("{} action=neo4j_remove_failed user={} target={} reason={}", LOG_PREFIX, userUuid,
                        targetUserUuid, e.getMessage());
            }
        });
    }

    @Transactional(readOnly = true)
    public FriendRelationshipDto getRelationshipStatus(String userUuid, String targetUserUuid) {
        if (userUuid.equals(targetUserUuid)) {
            log.debug("{} action=get_relationship_status result=self user={}", LOG_PREFIX, userUuid);
            return FriendRelationshipDto.builder().status("self").build();
        }

        User user = getRequiredUser(userUuid, "User");
        User target = userRepository.findByUuid(targetUserUuid)
                .orElseThrow(() -> new IllegalArgumentException("Target user not found"));

        if (friendshipRepository.existsByUserAndFriend(user, target)) {
            log.debug("{} action=get_relationship_status result=friends user={} target={}", LOG_PREFIX, userUuid,
                    targetUserUuid);
            return FriendRelationshipDto.builder().status("friends").build();
        }

        var sentRequest = friendRequestRepository.findBySenderAndReceiverAndStatus(user, target,
                FriendRequestStatus.PENDING);
        if (sentRequest.isPresent()) {
            log.debug("{} action=get_relationship_status result=request_sent user={} target={} requestId={}",
                    LOG_PREFIX, userUuid, targetUserUuid, sentRequest.get().getId());
            return FriendRelationshipDto.builder()
                    .status("request_sent")
                    .requestId(sentRequest.get().getId())
                    .build();
        }

        var receivedRequest = friendRequestRepository.findBySenderAndReceiverAndStatus(target, user,
                FriendRequestStatus.PENDING);
        if (receivedRequest.isPresent()) {
            log.debug("{} action=get_relationship_status result=request_received user={} target={} requestId={}",
                    LOG_PREFIX, userUuid, targetUserUuid, receivedRequest.get().getId());
            return FriendRelationshipDto.builder()
                    .status("request_received")
                    .requestId(receivedRequest.get().getId())
                    .build();
        }

        log.debug("{} action=get_relationship_status result=none user={} target={}", LOG_PREFIX, userUuid,
                targetUserUuid);
        return FriendRelationshipDto.builder().status("none").build();
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "user_friends", key = "#userUuid")
    public List<FriendDto> getFriends(String userUuid) {
        User user = userRepository.findByUuid(userUuid)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        List<Friendship> friendships = friendshipRepository.findByUser(user);

        List<FriendDto> friendDtos = friendships.stream().map(f -> {
            User friend = f.getFriend();
            int mutualCount = queryMutualCount(userUuid, friend.getUuid());
            return FriendDto.builder()
                    .uuid(friend.getUuid())
                    .riderId(friend.getRiderId())
                    .firstName(friend.getFirstName())
                    .lastName(friend.getLastName())
                    .username(friend.getUsername())
                    .profileImage(friend.getProfileImage())
                    .city(friend.getCity())
                    .mutualFriends(mutualCount)
                    .build();
        }).collect(Collectors.toList());
        log.debug("{} action=get_friends_completed user={} count={}", LOG_PREFIX, userUuid, friendDtos.size());
        return friendDtos;
    }

    @Transactional(readOnly = true)
    public List<PendingRequestDto> getPendingRequests(String receiverUuid) {
        User receiver = getRequiredUser(receiverUuid, "User");
        List<PendingRequestDto> pendingRequests = friendRequestRepository.findByReceiverAndStatus(receiver,
                        FriendRequestStatus.PENDING)
                .stream().map(req -> {
                    User sender = req.getSender();
                    int mutualCount = queryMutualCount(receiverUuid, sender.getUuid());
                    return PendingRequestDto.builder()
                            .requestId(req.getId())
                            .senderUuid(sender.getUuid())
                            .senderRiderId(sender.getRiderId())
                            .senderFirstName(sender.getFirstName())
                            .senderLastName(sender.getLastName())
                            .senderUsername(sender.getUsername())
                            .senderProfileImage(sender.getProfileImage())
                            .createdAt(req.getCreatedAt())
                            .mutualCount(mutualCount)
                            .build();
                }).collect(Collectors.toList());
        log.debug("{} action=get_pending_requests_completed user={} count={}", LOG_PREFIX, receiverUuid,
                pendingRequests.size());
        return pendingRequests;
    }

    @Transactional(readOnly = true)
    public List<FriendDto> getRecommendations(String userUuid) {
        log.debug("{} action=get_recommendations_start user={}", LOG_PREFIX, userUuid);
        User currentUser = userRepository.findByUuid(userUuid).orElse(null);
        if (currentUser == null) {
            log.warn("{} action=get_recommendations_blocked reason=user_not_found user={}", LOG_PREFIX, userUuid);
            return List.of();
        }

        Set<String> existingFriendUuids = friendshipRepository.findByUser(currentUser).stream()
                .map(Friendship::getFriend)
                .map(User::getUuid)
                .collect(Collectors.toSet());

        Set<String> sentPendingUuids = new HashSet<>();
        friendRequestRepository.findBySenderAndStatus(currentUser, FriendRequestStatus.PENDING)
                .forEach(r -> sentPendingUuids.add(r.getReceiver().getUuid()));

        Set<String> receivedPendingUuids = new HashSet<>();
        friendRequestRepository.findByReceiverAndStatus(currentUser, FriendRequestStatus.PENDING)
                .forEach(r -> receivedPendingUuids.add(r.getSender().getUuid()));

        List<FriendDto> mutualResults = new ArrayList<>();
        Set<String> mutualUuids = new HashSet<>();

        try {
            String cypher = "MATCH (u1:User {id: $userId})-[:FRIENDS_WITH]-(f:User)-[:FRIENDS_WITH]-(u2:User) "
                    + "WHERE NOT (u1)-[:FRIENDS_WITH]-(u2) AND u1 <> u2 "
                    + "RETURN u2.id AS id, count(f) AS mutualCount "
                    + "ORDER BY mutualCount DESC LIMIT 20";

            record Rec(String id, long mutualCount) {
            }

            List<Rec> recs = neo4jClient.query(cypher)
                    .bind(userUuid).to("userId")
                    .fetchAs(Rec.class)
                    .mappedBy((ts, row) -> new Rec(row.get("id").asString(), row.get("mutualCount").asLong()))
                    .all().stream().toList();

            log.info("{} action=get_recommendations_neo4j user={} mutualCandidates={}", LOG_PREFIX, userUuid,
                    recs.size());

            for (Rec rec : recs) {
                if (receivedPendingUuids.contains(rec.id())) {
                    continue;
                }
                User u = userRepository.findByUuid(rec.id()).orElse(null);
                if (u == null || !u.isActive()) {
                    continue;
                }
                mutualResults.add(FriendDto.builder()
                        .uuid(u.getUuid())
                        .riderId(u.getRiderId())
                        .firstName(u.getFirstName())
                        .lastName(u.getLastName())
                        .username(u.getUsername())
                        .profileImage(u.getProfileImage())
                        .city(u.getCity())
                        .requestSent(sentPendingUuids.contains(u.getUuid()))
                        .mutualFriends((int) rec.mutualCount())
                        .build());
                mutualUuids.add(rec.id());
            }
        } catch (Exception e) {
            log.warn("{} action=get_recommendations_neo4j_failed user={} reason={}", LOG_PREFIX, userUuid,
                    e.getMessage());
        }

        List<User> fallbackCandidates = new ArrayList<>();

        // 1. Fetch latest registered users to ensure "fresh" unlinked accounts are discoverable immediately
        fallbackCandidates.addAll(userRepository.findAll(
                PageRequest.of(0, 50, org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "createdAt"))
        ).getContent());

        // 2. Fetch a random page slice of the entire user base for organic varied discovery on reload
        long totalUsers = userRepository.count();
        if (totalUsers > 50) {
            int totalPages = (int) (totalUsers / 50);
            int randomPage = totalPages > 0 ? new java.util.Random().nextInt(totalPages) : 0;
            fallbackCandidates.addAll(userRepository.findAll(PageRequest.of(randomPage, 50)).getContent());
        }

        // 3. Shuffle combination for highly dynamic presentation
        java.util.Collections.shuffle(fallbackCandidates);

        java.util.Set<String> seenCandidateUuids = new HashSet<>();

        List<FriendDto> nonMutualResults = fallbackCandidates.stream()
                .filter(u -> seenCandidateUuids.add(u.getUuid()))
                .filter(u -> u.isActive()
                        && !u.getUuid().equals(userUuid)
                        && !existingFriendUuids.contains(u.getUuid())
                        && !mutualUuids.contains(u.getUuid())
                        && !receivedPendingUuids.contains(u.getUuid()))
                .limit(20)
                .map(u -> FriendDto.builder()
                        .uuid(u.getUuid())
                        .riderId(u.getRiderId())
                        .firstName(u.getFirstName())
                        .lastName(u.getLastName())
                        .username(u.getUsername())
                        .profileImage(u.getProfileImage())
                        .city(u.getCity())
                        .requestSent(sentPendingUuids.contains(u.getUuid()))
                        .mutualFriends(0)
                        .build())
                .collect(Collectors.toList());

        List<FriendDto> combined = new ArrayList<>(mutualResults);
        combined.addAll(nonMutualResults);
        log.info("{} action=get_recommendations_completed user={} total={} mutual={} fallback={}", LOG_PREFIX,
                userUuid, combined.size(), mutualResults.size(), nonMutualResults.size());
        return combined;
    }

    @Transactional(readOnly = true)
    public Integer getMutualFriendsCount(String currentUserUuid, String targetUserUuid) {
        int count = queryMutualCount(currentUserUuid, targetUserUuid);
        log.debug("{} action=get_mutual_count_completed user={} target={} count={}", LOG_PREFIX,
                currentUserUuid, targetUserUuid, count);
        return count;
    }
}
