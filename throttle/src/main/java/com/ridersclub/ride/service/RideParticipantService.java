package com.ridersclub.ride.service;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;

import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.MessageType;
import com.ridersclub.common.enums.RideInvitationStatus;
import com.ridersclub.common.enums.RideParticipantState;
import com.ridersclub.common.enums.Status;
import com.ridersclub.common.enums.UuidPrefix;
import com.ridersclub.common.enums.Visibility;
import com.ridersclub.friend.entity.Friendship;
import com.ridersclub.friend.repository.FriendshipRepository;
import com.ridersclub.message.entity.GroupMessage;
import com.ridersclub.message.repository.GroupMessageRepository;
import com.ridersclub.ride.entity.GroupMember;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.ClubMember;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.ride.entity.RideInvitation;
import com.ridersclub.ride.entity.RideLocation;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.common.enums.RideType;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.ride.dto.response.RideInviteCandidateResponse;
import com.ridersclub.ride.dto.response.RideInvitationResponse;
import com.ridersclub.ride.repository.ClubMemberRepository;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.dto.response.RideParticipantDto;
import com.ridersclub.ride.repository.GroupMemberRepository;
import com.ridersclub.ride.repository.RideInvitationRepository;
import com.ridersclub.ride.repository.RideGroupRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

@Slf4j
@Service
public class RideParticipantService {

    @Autowired
    private RideRepository rideRepository;
    @Autowired
    private RideParticipantRepository participantRepository;
    @Autowired
    private RideGroupRepository rideGroupRepository;
    @Autowired
    private GroupMemberRepository groupMemberRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private FriendshipRepository friendshipRepository;
    @Autowired
    private RideInvitationRepository rideInvitationRepository;
    @Autowired
    private ClubMemberRepository clubMemberRepository;
    @Autowired
    private NotificationService notificationService;
    @Autowired
    private GroupMessageRepository groupMessageRepository;
    @Autowired
    private RideSessionService rideSessionService;

    private boolean isRideManager(Role role) {
        return role == Role.CAPTAIN || role == Role.ADMIN || role == Role.CO_CAPTAIN;
    }

    private void ensureRideSupportsInvites(Ride ride) {
        if (ride.getRideType() == RideType.SOLO) {
            throw new RuntimeException("Solo rides do not support member invites");
        }
    }

    public List<RideParticipantDto> getRideParticipants(String rideId) {

    Ride ride = rideRepository.findByUuid(rideId)
            .orElseThrow(() -> new RuntimeException("Ride not found"));

    List<RideParticipant> participants = participantRepository.findByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED);

        return participants.stream()
            .map(rp -> RideParticipantDto.builder()
                    .userUuid(rp.getUser().getUuid())
                    .riderId(rp.getUser().getRiderId())
                    .firstName(rp.getUser().getFirstName())
                    .lastName(rp.getUser().getLastName())
                    .username(rp.getUser().getUsername())
                    .profileImage(rp.getUser().getProfileImage())
                    .role(rp.getRole().toString())
                    .rsvpStatus(rp.getRsvpStatus().toString())
                    .participantState((rp.getRideState() != null ? rp.getRideState() : RideParticipantState.JOINED).toString())
                    .joinedAt(rp.getJoinedAt())
                    .build())
            .toList();
}

    @Transactional
    public void updateRole(String rideUuid, String targetUserUuid, String role, String actorUserUuid) {
        Ride ride = rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                rideUuid, actorUserUuid, Status.EXITED)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (!isRideManager(actor.getRole())) {
            throw new RuntimeException("Only captain/admin can update roles");
        }

        RideParticipant target = participantRepository.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                rideUuid, targetUserUuid, Status.EXITED)
                .orElseThrow(() -> new RuntimeException("Rider not found in this ride"));

        Role newRole;
        try {
            newRole = Role.valueOf(role.toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new RuntimeException("Invalid role");
        }

        boolean selfDemotingOnlyAdmin = actor.getUser().getUuid().equals(target.getUser().getUuid())
                && actor.getRole() == Role.ADMIN
                && newRole != Role.ADMIN;
        if (selfDemotingOnlyAdmin) {
            long adminCount = participantRepository.findByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED).stream()
                    .filter(item -> item.getRole() == Role.ADMIN)
                    .count();
            if (adminCount <= 1) {
                throw new RuntimeException("Promote another admin before changing your role");
            }
        }

        target.setRole(newRole);
        participantRepository.save(target);

        syncTeamMembersSubgroup(ride, target.getUser(), newRole);
        rideSessionService.publishSessionUpdate(rideUuid);
    }

    @Transactional
    public void removeMember(String rideUuid, String targetUserUuid, String actorUserUuid) {
        Ride ride = rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                rideUuid, actorUserUuid, Status.EXITED)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (!isRideManager(actor.getRole())) {
            throw new RuntimeException("Only captain/admin can remove riders");
        }

        RideParticipant target = participantRepository.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                rideUuid, targetUserUuid, Status.EXITED)
                .orElseThrow(() -> new RuntimeException("Rider not found in this ride"));

        if (isRideManager(target.getRole())) {
            throw new RuntimeException("Captain/Admin cannot be removed from ride");
        }

        removeFromTeamMembersSubgroup(ride, target.getUser());
        participantRepository.delete(target);
        rideSessionService.publishSessionUpdate(rideUuid);
    }

    private void syncTeamMembersSubgroup(Ride ride, User user, Role role) {
        RideGroup teamMembersGroup = getOrCreateTeamMembersSubgroup(ride);
        boolean shouldBeTeamMember = role != Role.RIDER;

        if (shouldBeTeamMember) {
            if (!groupMemberRepository.existsByGroup_IdAndUser_Id(teamMembersGroup.getId(), user.getId())) {
                GroupMember member = new GroupMember();
                member.setGroup(teamMembersGroup);
                member.setUser(user);
                member.setRole(role.name());
                groupMemberRepository.save(member);
            } else {
                groupMemberRepository.findByGroup_IdAndUser_Id(teamMembersGroup.getId(), user.getId())
                        .ifPresent(member -> {
                            member.setRole(role.name());
                            groupMemberRepository.save(member);
                        });
            }
        } else {
            groupMemberRepository.deleteByGroup_IdAndUser_Id(teamMembersGroup.getId(), user.getId());
        }
    }

    private void removeFromTeamMembersSubgroup(Ride ride, User user) {
        RideGroup teamMembersGroup = getOrCreateTeamMembersSubgroup(ride);
        groupMemberRepository.deleteByGroup_IdAndUser_Id(teamMembersGroup.getId(), user.getId());
    }

    private RideGroup getOrCreateTeamMembersSubgroup(Ride ride) {
        RideGroup mainGroup = rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                .orElseThrow(() -> new RuntimeException("Main group not found"));

        return rideGroupRepository.findByRideAndParentGroupAndName(ride, mainGroup, "Team members")
                .orElseGet(() -> {
                    RideGroup subgroup = new RideGroup();
                    subgroup.setUuid(UserUtility.generateUUID(UuidPrefix.GROUP.name()));
                    subgroup.setRide(ride);
                    subgroup.setParentGroup(mainGroup);
                    subgroup.setName("Team members");
                    subgroup.setCreatedBy(ride.getCreatedBy());
                    subgroup.setVisibility(Visibility.PRIVATE);
                    subgroup.setMembersCanSendMessages(true);
                    subgroup.setMembersCanAddMembers(false);

                    RideGroup savedSubgroup = rideGroupRepository.save(subgroup);

                    if (!groupMemberRepository.existsByGroup_IdAndUser_Id(savedSubgroup.getId(), ride.getCreatedBy().getId())) {
                        GroupMember creatorMember = new GroupMember();
                        creatorMember.setGroup(savedSubgroup);
                        creatorMember.setUser(ride.getCreatedBy());
                        creatorMember.setRole(Role.ADMIN.name());
                        groupMemberRepository.save(creatorMember);
                    }

                    return savedSubgroup;
                });
    }

    @Transactional
    public void publishAnnouncement(String rideUuid, String message, String actorUserUuid) {
        Ride ride = rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                rideUuid, actorUserUuid, Status.EXITED)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (!isRideManager(actor.getRole())) {
            throw new RuntimeException("Only captain/admin can publish announcements");
        }

        List<RideParticipant> participants = participantRepository.findByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED);
        String actorName = ((actor.getUser().getFirstName() != null ? actor.getUser().getFirstName() : "")
                + " "
                + (actor.getUser().getLastName() != null ? actor.getUser().getLastName() : "")).trim();

        for (RideParticipant participant : participants) {
            notificationService.createAndSend(
                    participant.getUser().getId(),
                    NotificationType.ANNOUNCEMENT_PUBLISHED,
                    "New announcement in " + ride.getTitle(),
                    (actorName.isEmpty() ? "Captain" : actorName) + ": " + message,
                    ride.getId(),
                    "RIDE");
        }

        ride.setLatestBroadcastMessage(message);
        ride.setLatestBroadcastAt(LocalDateTime.now());
        rideRepository.save(ride);

        RideGroup mainGroup = rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                .orElseThrow(() -> new RuntimeException("Main group not found"));
        groupMessageRepository.save(GroupMessage.builder()
                .uuid(UserUtility.generateUUID(UuidPrefix.CHAT.name()))
                .sender(actor.getUser())
                .group(mainGroup)
                .message("Captain broadcast: " + message)
                .messageType(MessageType.SYSTEM)
                .edited(false)
                .build());
        rideSessionService.publishSessionUpdate(rideUuid);
    }

    @Transactional(readOnly = true)
    public List<RideInviteCandidateResponse> getInviteCandidates(String rideUuid, String actorUserUuid) {
        Ride ride = rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));
        ensureRideSupportsInvites(ride);

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                rideUuid, actorUserUuid, Status.EXITED)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (!isRideManager(actor.getRole())) {
            throw new RuntimeException("Only captain/admin can invite riders");
        }

        Set<Long> participantIds = participantRepository.findByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED)
                .stream()
                .map(rider -> rider.getUser().getId())
                .collect(Collectors.toSet());

        Set<Long> pendingInviteeIds = rideInvitationRepository.findByRide_IdAndStatus(
                        ride.getId(),
                        RideInvitationStatus.PENDING)
                .stream()
                .map(invitation -> invitation.getInvitee().getId())
                .collect(Collectors.toSet());

        Set<Long> clubMemberIds = ride.getClub() == null
                ? Set.of()
                : clubMemberRepository.findByClub_Id(ride.getClub().getId())
                        .stream()
                        .map(ClubMember::getUser)
                        .map(User::getId)
                        .collect(Collectors.toSet());

        return friendshipRepository.findByUser(actor.getUser())
                .stream()
                .map(Friendship::getFriend)
                .filter(friend -> !friend.getUuid().equals(actorUserUuid))
                .filter(friend -> !participantIds.contains(friend.getId()))
                .sorted(Comparator
                        .comparing((User friend) -> !clubMemberIds.contains(friend.getId()))
                        .thenComparing(friend -> formatUserName(friend).toLowerCase()))
                .map(friend -> RideInviteCandidateResponse.builder()
                        .userUuid(friend.getUuid())
                        .riderId(friend.getRiderId())
                        .firstName(friend.getFirstName())
                        .lastName(friend.getLastName())
                        .username(friend.getUsername())
                        .profileImage(friend.getProfileImage())
                        .email(friend.getEmail())
                        .clubFriend(clubMemberIds.contains(friend.getId()))
                        .invitationPending(pendingInviteeIds.contains(friend.getId()))
                        .build())
                .toList();
    }

    @Transactional
    public RideInvitationResponse inviteMember(String rideUuid, String inviteeUuid, String actorUserUuid) {
        Ride ride = rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));
        ensureRideSupportsInvites(ride);

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                rideUuid, actorUserUuid, Status.EXITED)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (!isRideManager(actor.getRole())) {
            throw new RuntimeException("Only captain/admin can invite riders");
        }

        User invitee = userRepository.findByUuid(inviteeUuid)
                .orElseThrow(() -> new RuntimeException("Friend not found"));

        if (actor.getUser().getUuid().equals(inviteeUuid)) {
            throw new RuntimeException("You cannot invite yourself");
        }

        if (!friendshipRepository.existsByUserAndFriend(actor.getUser(), invitee)) {
            throw new RuntimeException("You can only invite friends to the ride");
        }

        if (participantRepository.existsByRide_IdAndUser_IdAndRsvpStatusNot(ride.getId(), invitee.getId(), Status.EXITED)) {
            throw new RuntimeException("This rider is already part of the group");
        }

        if (rideInvitationRepository.existsByRide_IdAndInvitee_IdAndStatus(
                ride.getId(),
                invitee.getId(),
                RideInvitationStatus.PENDING)) {
            throw new RuntimeException("An invitation is already pending for this rider");
        }

        RideInvitation invitation = new RideInvitation();
        invitation.setRide(ride);
        invitation.setInviter(actor.getUser());
        invitation.setInvitee(invitee);
        invitation.setStatus(RideInvitationStatus.PENDING);

        RideInvitation savedInvitation = rideInvitationRepository.save(invitation);

        notificationService.createAndSend(
                invitee.getId(),
                NotificationType.RIDE_INVITE,
                "Ride group invitation",
                formatUserName(actor.getUser()) + " invited you to join \"" + ride.getTitle() + "\".",
                savedInvitation.getId(),
                "RIDE_INVITATION");

        return mapInvitationResponse(savedInvitation);
    }

    @Transactional(readOnly = true)
    public RideInvitationResponse getInvitationDetails(Long invitationId, String actorUserUuid) {
        RideInvitation invitation = rideInvitationRepository.findById(invitationId)
                .orElseThrow(() -> new RuntimeException("Invitation not found"));

        boolean isInvitee = invitation.getInvitee().getUuid().equals(actorUserUuid);
        boolean isInviter = invitation.getInviter().getUuid().equals(actorUserUuid);
        if (!isInvitee && !isInviter) {
            throw new RuntimeException("You are not allowed to view this invitation");
        }

        return mapInvitationResponse(invitation);
    }

    @Transactional
    public void acceptInvitation(Long invitationId, String inviteeUuid) {
        RideInvitation invitation = rideInvitationRepository.findByIdAndInvitee_Uuid(invitationId, inviteeUuid)
                .orElseThrow(() -> new RuntimeException("Invitation not found"));

        if (invitation.getStatus() != RideInvitationStatus.PENDING) {
            throw new RuntimeException("This invitation has already been responded to");
        }

        Ride ride = invitation.getRide();
        User invitee = invitation.getInvitee();

        RideParticipant existingParticipant = participantRepository.findByRide_UuidAndUser_Uuid(ride.getUuid(), invitee.getUuid())
                .orElse(null);
        if (existingParticipant == null) {
            participantRepository.save(new RideParticipant(ride, invitee, Role.RIDER, Status.CREATED));
        } else if (existingParticipant.getRsvpStatus() == Status.EXITED) {
            existingParticipant.setRsvpStatus(Status.CREATED);
            existingParticipant.setRole(Role.RIDER);
            participantRepository.save(existingParticipant);
        }

        RideGroup mainGroup = rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                .orElseThrow(() -> new RuntimeException("Main group not found"));

        if (!groupMemberRepository.existsByGroup_IdAndUser_Id(mainGroup.getId(), invitee.getId())) {
            GroupMember member = new GroupMember();
            member.setGroup(mainGroup);
            member.setUser(invitee);
            member.setRole(Role.RIDER.name());
            groupMemberRepository.save(member);
        }

        invitation.setStatus(RideInvitationStatus.ACCEPTED);
        invitation.setRespondedAt(LocalDateTime.now());
        rideInvitationRepository.save(invitation);
        createSystemGroupMessage(mainGroup, invitee, formatUserName(invitee) + " joined the group.");

        notificationService.createAndSend(
                invitation.getInviter().getId(),
                NotificationType.RIDE_JOINED,
                "Ride invitation accepted",
                formatUserName(invitee) + " accepted your invite to \"" + ride.getTitle() + "\".",
                invitation.getId(),
                "RIDE_INVITATION");
        rideSessionService.publishSessionUpdate(ride.getUuid());
    }

    @Transactional
    public void rejectInvitation(Long invitationId, String inviteeUuid) {
        RideInvitation invitation = rideInvitationRepository.findByIdAndInvitee_Uuid(invitationId, inviteeUuid)
                .orElseThrow(() -> new RuntimeException("Invitation not found"));

        if (invitation.getStatus() != RideInvitationStatus.PENDING) {
            throw new RuntimeException("This invitation has already been responded to");
        }

        invitation.setStatus(RideInvitationStatus.REJECTED);
        invitation.setRespondedAt(LocalDateTime.now());
        rideInvitationRepository.save(invitation);

        notificationService.createAndSend(
                invitation.getInviter().getId(),
                NotificationType.RIDE_REJECTED,
                "Ride invitation rejected",
                formatUserName(invitation.getInvitee()) + " declined your invite to \"" + invitation.getRide().getTitle() + "\".",
                invitation.getId(),
                "RIDE_INVITATION");
    }

    @Transactional
    public void leaveRide(String rideUuid, String actorUserUuid) {
        Ride ride = rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                rideUuid, actorUserUuid, Status.EXITED)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (isRideManager(actor.getRole())) {
            boolean hasOtherManager = participantRepository.findByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED)
                    .stream()
                    .filter(member -> !member.getUser().getId().equals(actor.getUser().getId()))
                    .anyMatch(member -> isRideManager(member.getRole()));

            if (!hasOtherManager) {
                throw new RuntimeException("Assign another admin/captain before leaving this ride");
            }

            RideParticipant replacement = participantRepository.findByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED)
                    .stream()
                    .filter(member -> !member.getUser().getId().equals(actor.getUser().getId()))
                    .filter(member -> isRideManager(member.getRole()))
                    .findFirst()
                    .orElse(null);

            if (ride.getCaptain() != null
                    && ride.getCaptain().getId().equals(actor.getUser().getId())
                    && replacement != null) {
                ride.setCaptain(replacement.getUser());
                rideRepository.save(ride);
            }
        }

        groupMemberRepository.deleteByGroup_Ride_IdAndUser_Id(ride.getId(), actor.getUser().getId());
        RideGroup mainGroup = rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                .orElseThrow(() -> new RuntimeException("Main group not found"));
        actor.setRsvpStatus(Status.EXITED);
        actor.setRideState(RideParticipantState.DROPPED);
        actor.setStateUpdatedAt(LocalDateTime.now());
        participantRepository.save(actor);
        createSystemGroupMessage(mainGroup, actor.getUser(), formatUserName(actor.getUser()) + " left the group.");
        rideSessionService.publishSessionUpdate(rideUuid);
    }

    private RideInvitationResponse mapInvitationResponse(RideInvitation invitation) {
        Ride ride = invitation.getRide();
        RideLocation startLocation = ride.getLocations()
                .stream()
                .filter(location -> location.getSequence() != null && location.getSequence() == 0)
                .findFirst()
                .orElseGet(() -> ride.getLocations().stream().findFirst().orElse(null));

        return RideInvitationResponse.builder()
                .id(invitation.getId())
                .rideUuid(ride.getUuid())
                .rideTitle(ride.getTitle())
                .rideDescription(ride.getDescription())
                .rideStartTime(ride.getStartTime())
                .meetingPoint(startLocation != null ? startLocation.getName() : null)
                .inviterUuid(invitation.getInviter().getUuid())
                .inviterName(formatUserName(invitation.getInviter()))
                .inviteeUuid(invitation.getInvitee().getUuid())
                .inviteeName(formatUserName(invitation.getInvitee()))
                .status(invitation.getStatus())
                .createdAt(invitation.getCreatedAt())
                .respondedAt(invitation.getRespondedAt())
                .build();
    }

    private String formatUserName(User user) {
        String firstName = user.getFirstName() != null ? user.getFirstName().trim() : "";
        String lastName = user.getLastName() != null ? user.getLastName().trim() : "";
        String fullName = (firstName + " " + lastName).trim();
        return fullName.isEmpty() ? "Someone" : fullName;
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

}
