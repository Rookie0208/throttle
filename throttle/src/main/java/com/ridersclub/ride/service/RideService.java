package com.ridersclub.ride.service;

import java.nio.file.AccessDeniedException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import org.springframework.transaction.annotation.Transactional;
import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.LocationType;
import com.ridersclub.common.enums.GroupJoinRequestStatus;
import com.ridersclub.common.enums.MessageType;
import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.common.enums.RideType;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.Status;
import com.ridersclub.common.enums.UuidPrefix;
import com.ridersclub.common.enums.Visibility;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.message.entity.GroupMessage;
import com.ridersclub.message.repository.GroupMessageRepository;
import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.dto.request.CreateSubGroupRequest;
import com.ridersclub.ride.dto.request.RideSummaryRequest;
import com.ridersclub.ride.dto.request.UpdateGroupRequest;
import com.ridersclub.ride.dto.request.UpdatePreRideInfoRequest;
import com.ridersclub.ride.dto.response.GroupJoinRequestResponse;
import com.ridersclub.ride.dto.response.GroupMemberResponse;
import com.ridersclub.ride.dto.response.MyRidesResp;
import com.ridersclub.ride.dto.response.PreRideInfoResponse;
import com.ridersclub.ride.dto.response.RideLocationResp;
import com.ridersclub.ride.dto.response.SubGroupResponse;
import com.ridersclub.ride.entity.GroupMember;
import com.ridersclub.ride.entity.GroupJoinRequest;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.ride.entity.RideLocation;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.ride.entity.RideRule;
import com.ridersclub.ride.entity.RideStats;
import com.ridersclub.ride.repository.GroupMemberRepository;
import com.ridersclub.ride.repository.GroupJoinRequestRepository;
import com.ridersclub.ride.repository.RideGroupRepository;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.repository.RideStatsRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

@Service
@Transactional
public class RideService {
        private static final Logger logger = LoggerFactory.getLogger(RideService.class);

        @Autowired
        private RideRepository rideRepository;
        @Autowired
        private RideParticipantRepository participantRepo;
        @Autowired
        private RideStatsRepository statsRepo;
        @Autowired
        private UserRepository userRepository;
        @Autowired
        private NotificationService notificationService;
        @Autowired
        private RideGroupRepository rideGroupRepository;
        @Autowired
        private GroupMemberRepository groupMemberRepository;
        @Autowired
        private GroupJoinRequestRepository groupJoinRequestRepository;
        @Autowired
        private GroupMessageRepository groupMessageRepository;
        @Autowired
        private RideSessionService rideSessionService;

        public Ride createRide(CreateRideRequest request, String currentUserUUId) throws AccessDeniedException {
                User currentUser = userRepository.findByUuid(currentUserUUId)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                if (request.getStartTime() == null || !request.getStartTime().isAfter(LocalDateTime.now())) {
                        throw new IllegalArgumentException("Ride start time must be in the future");
                }

                Ride ride = new Ride();
                ride.setTitle(request.getTitle());
                ride.setDescription(request.getDescription());
                ride.setRouteType(request.getRouteType());
                ride.setRideType(request.getRideType());
                ride.setStartTime(request.getStartTime());
                ride.setMaxRiders(request.getMaxRiders());
                ride.setVisibility(request.getVisibility());
                ride.setStatus(Status.SCHEDULED);
                ride.setCurrentCheckpointIndex(0);

                List<RideRule> rideRules = new ArrayList<>();
                for (int i = 0; i < request.getRules().size(); i++) {

                        RideRule rule = new RideRule(request.getRules().get(i));
                        rule.setRide(ride);
                        rule.setCreatedBy(currentUser);
                        rule.setRuleOrder(i);

                        rideRules.add(rule);
                }
                ride.setRules(rideRules);

                ride.setUuid(UserUtility.generateUUID(UuidPrefix.RIDE.name()));
                ride.setCaptain(currentUser);

                RideLocation start = new RideLocation();
                start.setName(request.getStartLocation().getName());
                start.setLatitude(request.getStartLocation().getLatitude());
                start.setLongitude(request.getStartLocation().getLongitude());
                start.setLocationType(LocationType.START);
                start.setSequence(1);
                start.setRide(ride);

                ride.addLocation(start);

                RideLocation end = new RideLocation();
                end.setName(request.getEndLocation().getName());
                end.setLatitude(request.getEndLocation().getLatitude());
                end.setLongitude(request.getEndLocation().getLongitude());
                end.setLocationType(LocationType.END);
                end.setSequence(2);
                end.setRide(ride);

                ride.addLocation(end);

                ride.setCreatedBy(currentUser);

                Ride saved = rideRepository.save(ride);
                participantRepo.save(new RideParticipant(saved, currentUser));
                logger.debug("Ride created with ID: " + saved.getUuid() + " and Captain ID: "
                                + saved.getCaptain().getId());
                logger.debug("full ride details: " + ride);

                if (saved.getRideType() == RideType.GROUP) {

                        RideGroup mainGroup = new RideGroup();
                        mainGroup.setUuid(UserUtility.generateUUID(UuidPrefix.GROUP.name()));
                        mainGroup.setRide(saved);
                        mainGroup.setName(saved.getTitle() + " - Main Group");
                        mainGroup.setCreatedBy(currentUser);

                        RideGroup savedGroup = rideGroupRepository.save(mainGroup);

                        GroupMember captainMember = new GroupMember();
                        captainMember.setGroup(savedGroup);
                        captainMember.setUser(currentUser);
                        captainMember.setRole("ADMIN");

                        groupMemberRepository.save(captainMember);
                        createTeamMembersSubGroup(saved, savedGroup, currentUser);
                } else {
                        RideGroup mainGroup = new RideGroup();
                        mainGroup.setUuid(UserUtility.generateUUID(UuidPrefix.GROUP.name()));
                        mainGroup.setRide(saved);
                        mainGroup.setName(saved.getTitle() + " - SOLO Ride");
                        mainGroup.setCreatedBy(currentUser);

                        RideGroup savedGroup = rideGroupRepository.save(mainGroup);

                        GroupMember captainMember = new GroupMember();
                        captainMember.setGroup(savedGroup);
                        captainMember.setUser(currentUser);
                        captainMember.setRole("ADMIN");
                        groupMemberRepository.save(captainMember);
                }

                notificationService.createAndSend(
                                currentUser.getId(),
                                "RIDE_CREATED",
                                "Ride Created",
                                "Your ride \"" + ride.getTitle() + "\" has been created successfully.",
                                saved.getId(),
                                "RIDE");

                System.out.println("notification published");

                return saved;
        }

        private RideGroup createTeamMembersSubGroup(Ride ride, RideGroup mainGroup, User creator) {
                RideGroup teamMembersGroup = new RideGroup();
                teamMembersGroup.setUuid(UserUtility.generateUUID(UuidPrefix.GROUP.name()));
                teamMembersGroup.setRide(ride);
                teamMembersGroup.setParentGroup(mainGroup);
                teamMembersGroup.setName("Team members");
                teamMembersGroup.setCreatedBy(creator);
                teamMembersGroup.setVisibility(Visibility.PRIVATE);
                teamMembersGroup.setMembersCanSendMessages(true);
                teamMembersGroup.setMembersCanAddMembers(false);

                RideGroup savedTeamMembersGroup = rideGroupRepository.save(teamMembersGroup);

                GroupMember creatorMember = new GroupMember();
                creatorMember.setGroup(savedTeamMembersGroup);
                creatorMember.setUser(creator);
                creatorMember.setRole("ADMIN");
                groupMemberRepository.save(creatorMember);

                return savedTeamMembersGroup;
        }

        public SubGroupResponse createSubGroup(CreateSubGroupRequest request, String userUuid) {

                User user = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                Ride ride = rideRepository.findByUuid(request.getRideUuid())
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                RideParticipant actor = participantRepo.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                                ride.getUuid(),
                                userUuid,
                                Status.EXITED)
                                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

                if (!isSubGroupManager(actor.getRole().name())) {
                        throw new RuntimeException("Only captain/admin can create subgroups");
                }

                if (request.getVisibility() == null) {
                        throw new RuntimeException("Please select subgroup visibility");
                }

                RideGroup mainGroup = rideGroupRepository
                                .findByRideAndParentGroupIsNull(ride)
                                .orElseThrow(() -> new RuntimeException("Main group not found"));

                RideGroup subGroup = new RideGroup();

                subGroup.setUuid(UserUtility.generateUUID(UuidPrefix.GROUP.name()));
                subGroup.setName(request.getName());
                subGroup.setVisibility(request.getVisibility());
                subGroup.setMembersCanSendMessages(request.isMembersCanSendMessages());
                subGroup.setMembersCanAddMembers(request.isMembersCanAddMembers());
                subGroup.setAdminsApproveMembers(request.isAdminsApproveMembers());
                subGroup.setParentGroup(mainGroup);
                subGroup.setRide(mainGroup.getRide());
                subGroup.setCreatedBy(user);

                RideGroup savedGroup = rideGroupRepository.save(subGroup);
                addGroupMemberIfMissing(subGroup, user, "ADMIN");
                if (request.getMemberUuids() != null) {
                        for (String memberUuid : request.getMemberUuids()) {
                                if (memberUuid == null || memberUuid.isBlank()) {
                                        continue;
                                }

                                User member = userRepository.findByUuid(memberUuid)
                                                .orElseThrow(() -> new RuntimeException("User not found"));

                                if (!participantRepo.existsByRide_IdAndUser_IdAndRsvpStatusNot(ride.getId(), member.getId(), Status.EXITED)) {
                                        throw new RuntimeException("Only ride members can be added to a subgroup");
                                }

                                addGroupMemberIfMissing(savedGroup, member, "RIDER");
                        }
                }

                notificationService.createAndSend(
                                user.getId(),
                                "SUBGROUP_CREATED",
                                "Subgroup Created",
                                "Your subgroup \"" + subGroup.getName() + "\" has been created successfully.",
                                savedGroup.getId(),
                                "RIDE");

                System.out.println("notification published");

                return buildSubGroupResponse(savedGroup, user);
        }

        private void addGroupMemberIfMissing(RideGroup group, User user, String role) {
                if (groupMemberRepository.existsByGroup_IdAndUser_Id(group.getId(), user.getId())) {
                        return;
                }

                GroupMember member = new GroupMember();
                member.setGroup(group);
                member.setUser(user);
                member.setRole(role);
                groupMemberRepository.save(member);
        }

        public void join(String rideId, String userId) {

                Ride ride = rideRepository.findByUuid(rideId)
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                if (ride.getStatus() != Status.CREATED && ride.getStatus() != Status.SCHEDULED) {
                        throw new RuntimeException("Ride already started. Cannot join.");
                }

                long currentCount = participantRepo.countByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED);
                RideParticipant existingParticipant = participantRepo
                                .findByRide_UuidAndUser_Uuid(rideId, userId)
                                .orElse(null);

                if (currentCount >= ride.getMaxRiders()) {
                        throw new RuntimeException("Ride is full");
                }

                User user = userRepository.findByUuid(userId)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                if (existingParticipant != null && existingParticipant.getRsvpStatus() != Status.EXITED)
                        throw new RuntimeException("Already joined");

                if (existingParticipant != null && existingParticipant.getRsvpStatus() == Status.EXITED) {
                        existingParticipant.setRsvpStatus(Status.CREATED);
                        participantRepo.save(existingParticipant);
                } else {
                        participantRepo.save(new RideParticipant(ride, user));
                }

                RideGroup mainGroup = rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                                .orElseThrow(() -> new RuntimeException("Main group not found"));
                addGroupMemberIfMissing(mainGroup, user, "RIDER");
                createSystemGroupMessage(mainGroup, user, formatUserName(user) + " joined the group.");

                // Notify captain that someone joined
                notificationService.createAndSend(
                                ride.getCreatedBy().getId(),
                                "RIDER_JOINED",
                                "New Rider Joined",
                                user.getFirstName() + " joined your ride \"" + ride.getTitle() + "\".",
                                ride.getId(),
                                "RIDE");
        }

        public List<MyRidesResp> myRides(String userId) {

                User currUser = userRepository.findByUuid(userId)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                List<RideParticipant> memberships = participantRepo.findByUser_Id(currUser.getId());

                List<MyRidesResp> myRides = memberships.stream()
                                .map(participant -> {
                                        Ride r = participant.getRide();
                                        return MyRidesResp.builder()
                                                .uuid(r.getUuid())
                                                .groupUuid(
                                                                rideGroupRepository.findByRideAndParentGroupIsNull(r)
                                                                                .orElseThrow(() -> new RuntimeException("RideGroup not found"))
                                                                                .getUuid())
                                                .title(r.getTitle())
                                                .description(r.getDescription())
                                                .rideType(r.getRideType())
                                                .routeType(r.getRouteType())
                                                .startTime(r.getStartTime())
                                                .endTime(r.getEndTime())
                                                .locations(r.getLocations().stream()
                                                                .map(loc -> RideLocationResp.builder()
                                                                                .name(loc.getName())
                                                                                .latitude(loc.getLatitude())
                                                                                .longitude(loc.getLongitude())
                                                                                .locationType(loc.getLocationType())
                                                                                .sequence(loc.getSequence())
                                                                                .build())
                                                                .toList())
                                                .maxRiders(r.getMaxRiders())
                                                .createdByUuid(r.getCreatedBy().getUuid())
                                                .createdByName(
                                                                ((r.getCreatedBy().getFirstName() != null
                                                                                ? r.getCreatedBy().getFirstName()
                                                                                : "")
                                                                                + " "
                                                                                + (r.getCreatedBy().getLastName() != null
                                                                                                ? r.getCreatedBy().getLastName()
                                                                                                : ""))
                                                                                                .trim())
                                                .captainUuid(r.getCaptain() != null ? r.getCaptain().getUuid() : null)
                                                .myRole(participant.getRole() != null ? participant.getRole().name() : null)
                                                .membershipStatus(participant.getRsvpStatus().name())
                                                .isMember(participant.getRsvpStatus() != Status.EXITED)
                                                .visibility(r.getVisibility())
                                                .status(r.getStatus())
                                                .createdAt(r.getCreatedAt().toLocalDateTime())
                                                .updatedAt(r.getUpdatedAt().toLocalDateTime())
                                                .build();
                                })
                                .toList();

                return myRides;
        }

        @Transactional(readOnly = true)
        public List<MyRidesResp> getPublicRides(String userUuid) {
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                return rideRepository.findByVisibility(Visibility.PUBLIC)
                                .stream()
                                .filter(ride -> ride.getStatus() == Status.CREATED || ride.getStatus() == Status.SCHEDULED)
                                .filter(ride -> ride.getStartTime() == null || ride.getStartTime().isAfter(LocalDateTime.now()))
                                .filter(ride -> !participantRepo.existsByRide_IdAndUser_IdAndRsvpStatusNot(
                                                ride.getId(),
                                                currentUser.getId(),
                                                Status.EXITED))
                                .map(ride -> MyRidesResp.builder()
                                                .uuid(ride.getUuid())
                                                .groupUuid(
                                                                rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                                                                                .map(RideGroup::getUuid)
                                                                                .orElse(null))
                                                .title(ride.getTitle())
                                                .description(ride.getDescription())
                                                .rideType(ride.getRideType())
                                                .routeType(ride.getRouteType())
                                                .startTime(ride.getStartTime())
                                                .endTime(ride.getEndTime())
                                                .maxRiders(ride.getMaxRiders())
                                                .createdByUuid(ride.getCreatedBy().getUuid())
                                                .createdByName(
                                                                ((ride.getCreatedBy().getFirstName() != null
                                                                                ? ride.getCreatedBy().getFirstName()
                                                                                : "")
                                                                                + " "
                                                                                + (ride.getCreatedBy().getLastName() != null
                                                                                                ? ride.getCreatedBy().getLastName()
                                                                                                : ""))
                                                                                                .trim())
                                                .captainUuid(ride.getCaptain() != null ? ride.getCaptain().getUuid() : null)
                                                .membershipStatus("AVAILABLE")
                                                .isMember(false)
                                                .visibility(ride.getVisibility())
                                                .status(ride.getStatus())
                                                .createdAt(ride.getCreatedAt().toLocalDateTime())
                                                .updatedAt(ride.getUpdatedAt().toLocalDateTime())
                                                .build())
                                .toList();
        }

        @Transactional(readOnly = true)
        public Ride getRideById(String id) {
                return rideRepository.findByUuid(id).orElseThrow(() -> new RuntimeException("Ride not found"));
        }

        @Transactional(readOnly = true)
        public List<RideParticipant> participants(String rideId) {
                Ride ride = rideRepository.findByUuid(rideId)
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                return participantRepo.findByRide_Id(ride.getId());

        }

        public void complete(String rideId, String userId) {

                Ride ride = rideRepository.findByUuid(rideId)
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                RideParticipant participant = participantRepo
                                .findByRide_UuidAndUser_Uuid(rideId, userId)
                                .orElseThrow(() -> new RuntimeException("Not part of ride"));

                if (participant.getRole() != Role.CAPTAIN
                                && participant.getRole() != Role.ADMIN
                                && participant.getRole() != Role.CO_CAPTAIN) {
                        throw new RuntimeException("Only captain can complete ride");
                }

                ride.setStatus(Status.COMPLETED);
                ride.setRideCompletedAt(LocalDateTime.now());
                ride.setEndTime(LocalDateTime.now());
                rideRepository.save(ride);
                rideSessionService.syncCompletionState(ride);
                rideSessionService.publishSessionUpdate(rideId);
        }

        public void addStats(String rideId, String userId, RideSummaryRequest req) {

                statsRepo.save(new RideStats(null, rideId, userId,
                                req.getDistanceKm(), req.getDurationMinutes(), req.getAvgSpeed()));
        }

        // ------------- DASHBOARD ------------------
        @Transactional(readOnly = true)
        public Map<String, Object> dashboard(String userId) {

                List<RideStats> stats = statsRepo.findByUserId(userId);

                double totalDistance = stats.stream().mapToDouble(RideStats::getDistanceKm).sum();
                long totalDuration = stats.stream().mapToLong(RideStats::getDurationMinutes).sum();

                return Map.of(
                                "totalRides", stats.size(),
                                "totalDistance", totalDistance,
                                "totalDuration", totalDuration);
        }

        public List<SubGroupResponse> getSubGroups(String rideUuid, String userUuid) {

                Ride ride = rideRepository.findByUuid(rideUuid)
                                .orElseThrow(() -> new RuntimeException("Ride not found"));
                List<RideGroup> groups = rideGroupRepository.findSubGroupsByRideUuid(rideUuid);
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                if (!participantRepo.existsByRide_IdAndUser_IdAndRsvpStatusNot(ride.getId(), currentUser.getId(), Status.EXITED)) {
                        throw new RuntimeException("You are not part of this ride");
                }

                return groups.stream()
                                .filter(group -> group.getVisibility() == Visibility.PUBLIC
                                                || groupMemberRepository.existsByGroup_IdAndUser_Id(
                                                                group.getId(), currentUser.getId()))
                                .map(group -> buildSubGroupResponse(group, currentUser))
                                .toList();
        }

        @Transactional(readOnly = true)
        public SubGroupResponse getGroupDetails(String groupUuid, String userUuid) {
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, currentUser);
                return buildSubGroupResponse(group, currentUser);
        }

        @Transactional(readOnly = true)
        public SubGroupResponse getMainGroupDetailsByRideUuid(String rideUuid, String userUuid) {
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                Ride ride = rideRepository.findByUuid(rideUuid)
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                if (!participantRepo.existsByRide_IdAndUser_IdAndRsvpStatusNot(
                                ride.getId(),
                                currentUser.getId(),
                                Status.EXITED)) {
                        throw new RuntimeException("You are not part of this ride");
                }

                RideGroup mainGroup = rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                                .orElseThrow(() -> new RuntimeException("Main group not found"));
                return buildSubGroupResponse(mainGroup, currentUser);
        }

        @Transactional(readOnly = true)
        public List<GroupMemberResponse> getGroupMembers(String groupUuid, String userUuid) {
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, currentUser);

                return groupMemberRepository.findByGroup_Id(group.getId())
                                .stream()
                                .map(member -> GroupMemberResponse.builder()
                                                .userUuid(member.getUser().getUuid())
                                                .firstName(member.getUser().getFirstName())
                                                .lastName(member.getUser().getLastName())
                                                .profileImage(member.getUser().getProfileImage())
                                                .role(member.getRole())
                                                .joinedAt(member.getJoinedAt())
                                                .build())
                                .toList();
        }

        @Transactional(readOnly = true)
        public List<GroupJoinRequestResponse> getPendingJoinRequests(String groupUuid, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                if (!canManageGroup(group, actorUser)) {
                        throw new RuntimeException("Only captain/admin can review join requests");
                }

                return groupJoinRequestRepository.findByGroup_IdAndStatusOrderByCreatedAtAsc(
                                group.getId(),
                                GroupJoinRequestStatus.PENDING)
                                .stream()
                                .map(request -> GroupJoinRequestResponse.builder()
                                                .requestId(request.getId())
                                                .userUuid(request.getUser().getUuid())
                                                .firstName(request.getUser().getFirstName())
                                                .lastName(request.getUser().getLastName())
                                                .profileImage(request.getUser().getProfileImage())
                                                .riderId(request.getUser().getRiderId())
                                                .groupUuid(group.getUuid())
                                                .groupName(group.getName())
                                                .status(request.getStatus())
                                                .requestedAt(request.getCreatedAt())
                                                .build())
                                .toList();
        }

        @Transactional(readOnly = true)
        public GroupJoinRequestResponse getJoinRequestDetails(Long requestId, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                GroupJoinRequest request = groupJoinRequestRepository.findById(requestId)
                                .orElseThrow(() -> new RuntimeException("Join request not found"));
                RideGroup group = request.getGroup();

                if (!canManageGroup(group, actorUser)) {
                        throw new RuntimeException("Only captain/admin can view join requests");
                }

                return GroupJoinRequestResponse.builder()
                                .requestId(request.getId())
                                .userUuid(request.getUser().getUuid())
                                .firstName(request.getUser().getFirstName())
                                .lastName(request.getUser().getLastName())
                                .profileImage(request.getUser().getProfileImage())
                                .riderId(request.getUser().getRiderId())
                                .groupUuid(group.getUuid())
                                .groupName(group.getName())
                                .status(request.getStatus())
                                .requestedAt(request.getCreatedAt())
                                .build();
        }

        public void updateGroupMemberRole(String groupUuid, String targetUserUuid, String role, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                GroupMember actor = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElseThrow(() -> new RuntimeException("You are not part of this subgroup"));

                if (!isSubGroupManager(actor.getRole())) {
                        throw new RuntimeException("Only captain/admin can update subgroup roles");
                }

                User targetUser = userRepository.findByUuid(targetUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                GroupMember target = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), targetUser.getId())
                                .orElseThrow(() -> new RuntimeException("Member not found in this subgroup"));

                target.setRole(role.toUpperCase());
                groupMemberRepository.save(target);
        }

        public void removeGroupMember(String groupUuid, String targetUserUuid, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                GroupMember actor = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElseThrow(() -> new RuntimeException("You are not part of this subgroup"));

                if (!isSubGroupManager(actor.getRole())) {
                        throw new RuntimeException("Only captain/admin can remove subgroup members");
                }

                User targetUser = userRepository.findByUuid(targetUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                GroupMember target = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), targetUser.getId())
                                .orElseThrow(() -> new RuntimeException("Member not found in this subgroup"));

                if (isSubGroupManager(target.getRole())) {
                        throw new RuntimeException("Captain/Admin cannot be removed from subgroup");
                }

                groupMemberRepository.delete(target);
        }

        public SubGroupResponse joinGroup(String groupUuid, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = rideGroupRepository.findByUuid(groupUuid)
                                .orElseThrow(() -> new RuntimeException("Group not found"));

                if (group.getParentGroup() == null) {
                        throw new RuntimeException("Use ride join to rejoin the main group");
                }

                if (group.getVisibility() != Visibility.PUBLIC) {
                        throw new RuntimeException("Only public subgroups can be joined directly");
                }

                        if (!participantRepo.existsByRide_IdAndUser_IdAndRsvpStatusNot(group.getRide().getId(), actorUser.getId(), Status.EXITED)) {
                                throw new RuntimeException("You must be part of the ride to join this subgroup");
                        }

                if (groupMemberRepository.existsByGroup_IdAndUser_Id(group.getId(), actorUser.getId())) {
                        return buildSubGroupResponse(group, actorUser);
                }

                if (Boolean.TRUE.equals(group.getAdminsApproveMembers())) {
                        if (groupJoinRequestRepository.findByGroup_IdAndUser_IdAndStatus(
                                        group.getId(),
                                        actorUser.getId(),
                                        GroupJoinRequestStatus.PENDING)
                                        .isPresent()) {
                                throw new RuntimeException("Join request already sent");
                        }

                        GroupJoinRequest request = new GroupJoinRequest();
                        request.setGroup(group);
                        request.setUser(actorUser);
                        request.setStatus(GroupJoinRequestStatus.PENDING);
                        groupJoinRequestRepository.save(request);
                        notifyGroupManagers(
                                        group,
                                        "SUBGROUP_JOIN_REQUEST",
                                        "Subgroup join request",
                                        actorUser.getFirstName() + " requested to join " + group.getName() + ".",
                                        request.getId(),
                                        "GROUP_JOIN_REQUEST");
                        return buildSubGroupResponse(group, actorUser);
                }

                addGroupMemberIfMissing(group, actorUser, "RIDER");
                groupJoinRequestRepository.deleteByGroup_IdAndUser_Id(group.getId(), actorUser.getId());
                createSystemGroupMessage(group, actorUser, formatUserName(actorUser) + " joined the subgroup.");
                return buildSubGroupResponse(group, actorUser);
        }

        public void approveJoinRequest(String groupUuid, Long requestId, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                if (!canManageGroup(group, actorUser)) {
                        throw new RuntimeException("Only captain/admin can approve join requests");
                }

                GroupJoinRequest request = groupJoinRequestRepository.findById(requestId)
                                .orElseThrow(() -> new RuntimeException("Join request not found"));

                if (!request.getGroup().getId().equals(group.getId())) {
                        throw new RuntimeException("Join request does not belong to this subgroup");
                }

                if (request.getStatus() != GroupJoinRequestStatus.PENDING) {
                        throw new RuntimeException("Join request is no longer pending");
                }

                if (!participantRepo.existsByRide_IdAndUser_IdAndRsvpStatusNot(group.getRide().getId(), request.getUser().getId(), Status.EXITED)) {
                        throw new RuntimeException("Requester is no longer part of the ride");
                }

                addGroupMemberIfMissing(group, request.getUser(), "RIDER");
                request.setStatus(GroupJoinRequestStatus.APPROVED);
                groupJoinRequestRepository.save(request);
                createSystemGroupMessage(group, request.getUser(), formatUserName(request.getUser()) + " joined the subgroup.");
                notificationService.createAndSend(
                                request.getUser().getId(),
                                "SUBGROUP_JOIN_APPROVED",
                                "Subgroup join approved",
                                "Your request to join " + group.getName() + " was approved.",
                                group.getId(),
                                "GROUP");
        }

        public void rejectJoinRequest(String groupUuid, Long requestId, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                if (!canManageGroup(group, actorUser)) {
                        throw new RuntimeException("Only captain/admin can reject join requests");
                }

                GroupJoinRequest request = groupJoinRequestRepository.findById(requestId)
                                .orElseThrow(() -> new RuntimeException("Join request not found"));

                if (!request.getGroup().getId().equals(group.getId())) {
                        throw new RuntimeException("Join request does not belong to this subgroup");
                }

                if (request.getStatus() != GroupJoinRequestStatus.PENDING) {
                        throw new RuntimeException("Join request is no longer pending");
                }

                request.setStatus(GroupJoinRequestStatus.REJECTED);
                groupJoinRequestRepository.save(request);
                notificationService.createAndSend(
                                request.getUser().getId(),
                                "SUBGROUP_JOIN_REJECTED",
                                "Subgroup join rejected",
                                "Your request to join " + group.getName() + " was rejected.",
                                group.getId(),
                                "GROUP");
        }

        public void leaveGroup(String groupUuid, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = rideGroupRepository.findByUuid(groupUuid)
                                .orElseThrow(() -> new RuntimeException("Group not found"));

                if (group.getParentGroup() == null) {
                        throw new RuntimeException("Use ride leave to exit the main group");
                }

                GroupMember membership = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElseThrow(() -> new RuntimeException("You are not a member of this subgroup"));

                if (isSubGroupManager(membership.getRole()) && !hasOtherGroupManager(group, actorUser)) {
                        throw new RuntimeException("Assign another admin/captain before leaving this subgroup");
                }

                groupMemberRepository.delete(membership);
                groupJoinRequestRepository.deleteByGroup_IdAndUser_Id(group.getId(), actorUser.getId());
                createSystemGroupMessage(group, actorUser, formatUserName(actorUser) + " left the subgroup.");
        }

        public SubGroupResponse renameGroup(String groupUuid, UpdateGroupRequest request, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                if (!canManageGroup(group, actorUser)) {
                        throw new RuntimeException("Only captain/admin can rename groups");
                }

                String name = request.getName() == null ? "" : request.getName().trim();
                if (name.isEmpty()) {
                        throw new RuntimeException("Group name is required");
                }

                if (group.getParentGroup() == null) {
                        group.getRide().setTitle(name);
                        group.setName(name);
                        rideRepository.save(group.getRide());
                } else {
                        group.setName(name);
                }

                RideGroup savedGroup = rideGroupRepository.save(group);
                return buildSubGroupResponse(savedGroup, actorUser);
        }

        private RideGroup getAccessibleGroup(String groupUuid, User currentUser) {
                RideGroup group = rideGroupRepository.findByUuid(groupUuid)
                                .orElseThrow(() -> new RuntimeException("Group not found"));

                boolean isRideParticipant = participantRepo.existsByRide_IdAndUser_IdAndRsvpStatusNot(
                                group.getRide().getId(),
                                currentUser.getId(),
                                Status.EXITED);
                boolean isRideManager = participantRepo.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                                group.getRide().getUuid(),
                                currentUser.getUuid(),
                                Status.EXITED)
                                .map(participant -> isSubGroupManager(participant.getRole().name()))
                                .orElse(false);

                boolean canAccess = isRideManager
                                || (group.getVisibility() == Visibility.PUBLIC && isRideParticipant)
                                || groupMemberRepository.existsByGroup_IdAndUser_Id(group.getId(), currentUser.getId());

                if (!canAccess) {
                        throw new RuntimeException("You are not allowed to access this subgroup");
                }

                return group;
        }

        private SubGroupResponse buildSubGroupResponse(RideGroup group, User currentUser) {
                GroupMember currentMembership = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), currentUser.getId())
                                .orElse(null);
                boolean isSubGroup = group.getParentGroup() != null;
                boolean isMember = currentMembership != null || !isSubGroup;
                boolean joinRequestPending = isSubGroup
                                && groupJoinRequestRepository.findByGroup_IdAndUser_IdAndStatus(
                                                group.getId(),
                                                currentUser.getId(),
                                                GroupJoinRequestStatus.PENDING)
                                                .isPresent();
                String createdByName = ((group.getCreatedBy().getFirstName() != null
                                ? group.getCreatedBy().getFirstName()
                                : "")
                                + " "
                                + (group.getCreatedBy().getLastName() != null
                                                ? group.getCreatedBy().getLastName()
                                                : ""))
                                                                .trim();

                return SubGroupResponse.builder()
                                .uuid(group.getUuid())
                                .name(group.getName())
                                .title(group.getParentGroup() == null ? group.getRide().getTitle() : group.getName())
                                .description(group.getRide().getDescription())
                                .rideUuid(group.getRide().getUuid())
                                .parentGroupUuid(
                                                group.getParentGroup() != null
                                                                ? group.getParentGroup().getUuid()
                                                                : null)
                                .visibility(group.getVisibility())
                                .membersCanSendMessages(group.getMembersCanSendMessages())
                                .membersCanAddMembers(group.getMembersCanAddMembers())
                                .adminsApproveMembers(Boolean.TRUE.equals(group.getAdminsApproveMembers()))
                                .createdByUuid(group.getCreatedBy().getUuid())
                                .createdByName(createdByName)
                                .myRole(currentMembership != null ? currentMembership.getRole() : null)
                                .isMember(isMember)
                                .joinRequestPending(joinRequestPending)
                                .canJoinDirectly(isSubGroup
                                                && group.getVisibility() == Visibility.PUBLIC
                                                && !isMember
                                                && !Boolean.TRUE.equals(group.getAdminsApproveMembers()))
                                .canRequestToJoin(isSubGroup
                                                && group.getVisibility() == Visibility.PUBLIC
                                                && !isMember
                                                && Boolean.TRUE.equals(group.getAdminsApproveMembers()))
                                .memberCount(groupMemberRepository.findByGroup_Id(group.getId()).size())
                                .preRideInfo(buildPreRideInfoMap(group))
                                .createdAt(group.getCreatedAt())
                                .build();
        }

        public void addGroupMembers(String groupUuid, List<String> memberUuids, String actorUserUuid) {
                if (memberUuids == null || memberUuids.isEmpty()) {
                        throw new RuntimeException("Select at least one member to add");
                }

                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                if (!canAddMembers(group, actorUser)) {
                        throw new RuntimeException("You do not have permission to add members to this subgroup");
                }

                List<String> uniqueMemberUuids = memberUuids.stream()
                                .filter(uuid -> uuid != null && !uuid.isBlank())
                                .distinct()
                                .toList();

                for (String memberUuid : uniqueMemberUuids) {
                        User member = userRepository.findByUuid(memberUuid)
                                        .orElseThrow(() -> new RuntimeException("User not found"));

                        if (!participantRepo.existsByRide_IdAndUser_IdAndRsvpStatusNot(group.getRide().getId(), member.getId(), Status.EXITED)) {
                                throw new RuntimeException("Only ride members can be added to a subgroup");
                        }

                        addGroupMemberIfMissing(group, member, "RIDER");
                }
        }

        public PreRideInfoResponse getPreRideInfo(String groupUuid, String userUuid) {
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, currentUser);
                return buildPreRideInfoResponse(group);
        }

        public PreRideInfoResponse updatePreRideInfo(
                        String groupUuid,
                        UpdatePreRideInfoRequest request,
                        String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                GroupMember actorMembership = groupMemberRepository
                                .findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElse(null);
                boolean actorIsRideManager = participantRepo.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                                group.getRide().getUuid(),
                                actorUserUuid,
                                Status.EXITED)
                                .map(participant -> isSubGroupManager(participant.getRole().name()))
                                .orElse(false);

                if (!(actorIsRideManager
                                || (actorMembership != null && isSubGroupManager(actorMembership.getRole())))) {
                        throw new RuntimeException("Only captain/admin can update pre-ride info");
                }

                group.setPreRideMeetingPoint(trimToNull(request.getMeetingPoint()));
                group.setPreRideFuelStops(trimToNull(request.getFuelStops()));
                group.setPreRideCheckpoints(joinList(request.getCheckpointList()));
                group.setPreRideRules(joinList(request.getRuleList()));
                group.setPreRideNotes(trimToNull(request.getNotes()));
                group.setPreRideUpdatedAt(LocalDateTime.now());

                RideGroup savedGroup = rideGroupRepository.save(group);
                return buildPreRideInfoResponse(savedGroup);
        }

        private PreRideInfoResponse buildPreRideInfoResponse(RideGroup group) {
                return PreRideInfoResponse.builder()
                                .title(group.getRide().getTitle())
                                .description(group.getRide().getDescription())
                                .rideType(group.getRide().getRideType())
                                .routeType(group.getRide().getRouteType())
                                .maxRiders(group.getRide().getMaxRiders())
                                .visibility(group.getVisibility())
                                .startTime(group.getRide().getStartTime())
                                .meetingPoint(group.getPreRideMeetingPoint())
                                .fuelStops(group.getPreRideFuelStops())
                                .checkpointList(splitList(group.getPreRideCheckpoints()))
                                .ruleList(splitList(group.getPreRideRules()))
                                .notes(group.getPreRideNotes())
                                .updatedAt(group.getPreRideUpdatedAt())
                                .build();
        }

        private Map<String, Object> buildPreRideInfoMap(RideGroup group) {
                PreRideInfoResponse response = buildPreRideInfoResponse(group);
                Map<String, Object> map = new LinkedHashMap<>();
                map.put("title", response.getTitle());
                map.put("description", response.getDescription());
                map.put("rideType", response.getRideType());
                map.put("routeType", response.getRouteType());
                map.put("maxRiders", response.getMaxRiders());
                map.put("visibility", response.getVisibility());
                map.put("startTime", response.getStartTime());
                map.put("meetingPoint", response.getMeetingPoint());
                map.put("fuelStops", response.getFuelStops());
                map.put("checkpointList", response.getCheckpointList());
                map.put("ruleList", response.getRuleList());
                map.put("notes", response.getNotes());
                map.put("updatedAt", response.getUpdatedAt());
                return map;
        }

        private List<String> splitList(String value) {
                if (value == null || value.isBlank()) {
                        return List.of();
                }
                return Arrays.stream(value.split(","))
                                .map(String::trim)
                                .filter(item -> !item.isEmpty())
                                .toList();
        }

        private String joinList(List<String> values) {
                if (values == null) {
                        return null;
                }
                return values.stream()
                                .filter(item -> item != null && !item.isBlank())
                                .map(String::trim)
                                .distinct()
                                .collect(Collectors.joining(", "));
        }

        private String trimToNull(String value) {
                if (value == null) {
                        return null;
                }
                String trimmed = value.trim();
                return trimmed.isEmpty() ? null : trimmed;
        }

        private boolean canAddMembers(RideGroup group, User actorUser) {
                GroupMember actorMembership = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElse(null);
                if (actorMembership != null && isSubGroupManager(actorMembership.getRole())) {
                        return true;
                }

                boolean actorIsRideManager = participantRepo.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                                group.getRide().getUuid(),
                                actorUser.getUuid(),
                                Status.EXITED)
                                .map(participant -> isSubGroupManager(participant.getRole().name()))
                                .orElse(false);
                if (actorIsRideManager) {
                        return true;
                }

                if (!Boolean.TRUE.equals(group.getMembersCanAddMembers())) {
                        return false;
                }

                if (Boolean.TRUE.equals(group.getAdminsApproveMembers())) {
                        return false;
                }

                return actorMembership != null
                                || (group.getVisibility() == Visibility.PUBLIC
                                                && participantRepo.existsByRide_IdAndUser_IdAndRsvpStatusNot(
                                                                group.getRide().getId(),
                                                                actorUser.getId(),
                                                                Status.EXITED));
        }

        private boolean canManageGroup(RideGroup group, User actorUser) {
                GroupMember actorMembership = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElse(null);
                if (actorMembership != null && isSubGroupManager(actorMembership.getRole())) {
                        return true;
                }

                return participantRepo.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                                group.getRide().getUuid(),
                                actorUser.getUuid(),
                                Status.EXITED)
                                .map(participant -> isSubGroupManager(participant.getRole().name()))
                                .orElse(false);
        }

        private boolean hasOtherGroupManager(RideGroup group, User actorUser) {
                return groupMemberRepository.findByGroup_Id(group.getId())
                                .stream()
                                .filter(member -> !member.getUser().getId().equals(actorUser.getId()))
                                .anyMatch(member -> isSubGroupManager(member.getRole()));
        }

        private void notifyGroupManagers(
                        RideGroup group,
                        String type,
                        String title,
                        String message,
                        Long referenceId,
                        String referenceType) {
                List<Long> managerIds = groupMemberRepository.findByGroup_Id(group.getId())
                                .stream()
                                .filter(member -> isSubGroupManager(member.getRole()))
                                .map(member -> member.getUser().getId())
                                .distinct()
                                .toList();

                for (Long managerId : managerIds) {
                        notificationService.createAndSend(
                                        managerId,
                                        type,
                                        title,
                                        message,
                                        referenceId,
                                        referenceType);
                }
        }

        private boolean isSubGroupManager(String role) {
                if (role == null) {
                        return false;
                }
                String normalizedRole = role.trim().toUpperCase();
                return normalizedRole.equals("CAPTAIN")
                                || normalizedRole.equals("ADMIN")
                                || normalizedRole.equals("CO_CAPTAIN");
        }

        private void createSystemGroupMessage(RideGroup group, User actor, String message) {
                groupMessageRepository.save(GroupMessage.builder()
                                .uuid(UserUtility.generateUUID(UuidPrefix.CHAT.name()))
                                .sender(actor)
                                .group(group)
                                .message(message)
                                .messageType(MessageType.SYSTEM)
                                .edited(false)
                                .build());
        }

        private String formatUserName(User user) {
                String firstName = user.getFirstName() != null ? user.getFirstName().trim() : "";
                String lastName = user.getLastName() != null ? user.getLastName().trim() : "";
                String fullName = (firstName + " " + lastName).trim();
                return fullName.isEmpty() ? "Someone" : fullName;
        }
}
