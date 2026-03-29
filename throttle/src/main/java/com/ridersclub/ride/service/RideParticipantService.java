package com.ridersclub.ride.service;

import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.UuidPrefix;
import com.ridersclub.common.enums.Visibility;
import com.ridersclub.ride.entity.GroupMember;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.dto.response.RideParticipantDto;
import com.ridersclub.ride.repository.GroupMemberRepository;
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
    private NotificationService notificationService;

    public List<RideParticipantDto> getRideParticipants(String rideId) {

    Ride ride = rideRepository.findByUuid(rideId)
            .orElseThrow(() -> new RuntimeException("Ride not found"));

    List<RideParticipant> participants = participantRepository.findByRide_Id(ride.getId());

    return participants.stream()
            .map(rp -> RideParticipantDto.builder()
                    .userUuid(rp.getUser().getUuid())
                    .riderId(rp.getUser().getRiderId())
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
                    subgroup.setUuid(UserUtility.generateUUID(UuidPrefix.group.name()));
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

}
