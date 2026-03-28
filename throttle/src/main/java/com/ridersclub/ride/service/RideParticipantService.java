package com.ridersclub.ride.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.RideInvitationStatus;
import com.ridersclub.common.enums.Status;
import com.ridersclub.common.enums.Visibility;
import com.ridersclub.friend.repository.FriendshipRepository;
import com.ridersclub.ride.entity.GroupMember;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.ride.entity.RideInvitation;
import com.ridersclub.ride.entity.RideLocation;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.ride.dto.response.RideInvitationResponse;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.dto.response.RideParticipantDto;
import com.ridersclub.ride.repository.GroupMemberRepository;
import com.ridersclub.ride.repository.RideInvitationRepository;
import com.ridersclub.ride.repository.RideGroupRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

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
    private NotificationService notificationService;

    public List<RideParticipantDto> getRideParticipants(String rideId) {

    Ride ride = rideRepository.findByUuid(rideId)
            .orElseThrow(() -> new RuntimeException("Ride not found"));

    List<RideParticipant> participants = participantRepository.findByRide_Id(ride.getId());

    return participants.stream()
            .map(rp -> RideParticipantDto.builder()
                    .userUuid(rp.getUser().getUuid())
                    .firstName(rp.getUser().getFirstName())
                    .lastName(rp.getUser().getLastName())
                    .profileImage(rp.getUser().getProfileImage())
                    .role(rp.getRole().toString())
                    .rsvpStatus(rp.getRsvpStatus().toString())
                    .joinedAt(rp.getJoinedAt())
                    .build())
            .toList();
}

    @Transactional
    public void updateRole(String rideUuid, String targetUserUuid, String role, String actorUserUuid) {
        Ride ride = rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_Uuid(rideUuid, actorUserUuid)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (!(actor.getRole() == Role.CAPTAIN || actor.getRole() == Role.ADMIN)) {
            throw new RuntimeException("Only captain/admin can update roles");
        }

        RideParticipant target = participantRepository.findByRide_UuidAndUser_Uuid(rideUuid, targetUserUuid)
                .orElseThrow(() -> new RuntimeException("Rider not found in this ride"));

        Role newRole;
        try {
            newRole = Role.valueOf(role.toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new RuntimeException("Invalid role");
        }

        target.setRole(newRole);
        participantRepository.save(target);

        syncTeamMembersSubgroup(ride, target.getUser(), newRole);
    }

    @Transactional
    public void removeMember(String rideUuid, String targetUserUuid, String actorUserUuid) {
        Ride ride = rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_Uuid(rideUuid, actorUserUuid)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (!(actor.getRole() == Role.CAPTAIN || actor.getRole() == Role.ADMIN)) {
            throw new RuntimeException("Only captain/admin can remove riders");
        }

        RideParticipant target = participantRepository.findByRide_UuidAndUser_Uuid(rideUuid, targetUserUuid)
                .orElseThrow(() -> new RuntimeException("Rider not found in this ride"));

        if (target.getRole() == Role.CAPTAIN || target.getRole() == Role.ADMIN) {
            throw new RuntimeException("Captain/Admin cannot be removed from ride");
        }

        removeFromTeamMembersSubgroup(ride, target.getUser());
        participantRepository.delete(target);
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
                    subgroup.setUuid(UUID.randomUUID().toString());
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

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_Uuid(rideUuid, actorUserUuid)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (!(actor.getRole() == Role.CAPTAIN || actor.getRole() == Role.ADMIN)) {
            throw new RuntimeException("Only captain/admin can publish announcements");
        }

        List<RideParticipant> participants = participantRepository.findByRide_Id(ride.getId());
        String actorName = ((actor.getUser().getFirstName() != null ? actor.getUser().getFirstName() : "")
                + " "
                + (actor.getUser().getLastName() != null ? actor.getUser().getLastName() : "")).trim();

        for (RideParticipant participant : participants) {
            notificationService.createAndSend(
                    participant.getUser().getId(),
                    "ANNOUNCEMENT_PUBLISHED",
                    "New announcement in " + ride.getTitle(),
                    (actorName.isEmpty() ? "Captain" : actorName) + ": " + message,
                    ride.getId(),
                    "RIDE");
        }
    }

    @Transactional
    public RideInvitationResponse inviteMember(String rideUuid, String inviteeUuid, String actorUserUuid) {
        Ride ride = rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        RideParticipant actor = participantRepository.findByRide_UuidAndUser_Uuid(rideUuid, actorUserUuid)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

        if (!(actor.getRole() == Role.CAPTAIN || actor.getRole() == Role.ADMIN)) {
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

        if (participantRepository.existsByRide_IdAndUser_Id(ride.getId(), invitee.getId())) {
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
                "RIDE_GROUP_INVITE",
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

        if (!participantRepository.existsByRide_IdAndUser_Id(ride.getId(), invitee.getId())) {
            participantRepository.save(new RideParticipant(ride, invitee, Role.RIDER, Status.CREATED));
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

        notificationService.createAndSend(
                invitation.getInviter().getId(),
                "RIDE_INVITE_ACCEPTED",
                "Ride invitation accepted",
                formatUserName(invitee) + " accepted your invite to \"" + ride.getTitle() + "\".",
                invitation.getId(),
                "RIDE_INVITATION");
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
                "RIDE_INVITE_REJECTED",
                "Ride invitation rejected",
                formatUserName(invitation.getInvitee()) + " declined your invite to \"" + invitation.getRide().getTitle() + "\".",
                invitation.getId(),
                "RIDE_INVITATION");
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

}
