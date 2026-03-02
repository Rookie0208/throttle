package com.ridersclub.group.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.Status;
import com.ridersclub.group.entity.Group;
import com.ridersclub.group.entity.GroupMember;
import com.ridersclub.group.repository.GroupMemberRepository;
import com.ridersclub.group.repository.GroupRepository;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.user.entity.User;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class GroupService {

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final RideRepository rideRepository;

    // 1️⃣ Create group when ride is created
    public Group createGroupForRide(Ride ride, User creator) {

        Group group = new Group();
        group.setName(ride.getTitle());
        group.setDescription("Ride group for " + ride.getTitle());
        group.setRideId(ride.getId());
        group.setCreatedBy(creator);

        Group savedGroup = groupRepository.save(group);

        // Add creator as ADMIN
        GroupMember member = new GroupMember();
        member.setGroup(savedGroup);
        member.setUser(creator);
        member.setRole(Role.ADMIN);

        // groupMemberRepository.save(member);

        return savedGroup;
    }

    // 2️⃣ Get all groups of a user
    // public List<Group> getUserGroups(User user) {
    //     List<GroupMember> memberships = groupMemberRepository.findByUser(user);

    //     return memberships.stream()
    //             .map(GroupMember::getGroup)
    //             .collect(Collectors.toList());
    // }

    public List<Group> getUserGroups(User user) {

    List<GroupMember> memberships = groupMemberRepository.findByUser(user);

    // If no groups exist for user → create dummy ones
    if (memberships == null || memberships.isEmpty()) {

        // Create dummy groups
        Group g1 = new Group();
        g1.setId(1L);
        g1.setName("Sunday Canyon Ride");
        g1.setDescription("Weekend long ride");
        g1.setStatus(Status.ACTIVE);

        Group g2 = new Group();
        g2.setId(2L);
        g2.setName("Mountain Explorers");
        g2.setDescription("Adventure seekers");
        g2.setStatus(Status.ARCHIVED);

        // Save groups (if you have groupRepository)
        groupRepository.save(g1);
        groupRepository.save(g2);

        // Create memberships
        GroupMember m1 = new GroupMember();
        m1.setId(1L);
        m1.setGroup(g1);
        m1.setUser(user);

        GroupMember m2 = new GroupMember();
        m2.setId(2L);
        m2.setGroup(g2);
        m2.setUser(user);

        groupMemberRepository.save(m1);
        groupMemberRepository.save(m2);

        memberships = List.of(m1, m2);
    }

    return memberships.stream()
            .map(GroupMember::getGroup)
            .collect(Collectors.toList());
}

    // 3️⃣ Get group details
    public Group getGroupById(Long groupId) {
        // return groupRepository.findById(groupId)
                // .orElseThrow(() -> new RuntimeException("Group not found"));
                return null;
    }

    // 4️⃣ Join group
    public void joinGroup(Long groupId, User user) {

        Group group = getGroupById(groupId);

        if (groupMemberRepository.existsByGroupAndUser(group, user)) {
            throw new RuntimeException("Already joined");
        }

        GroupMember member = new GroupMember();
        member.setGroup(group);
        member.setUser(user);
        member.setRole(Role.RIDER);

        // groupMemberRepository.save(member);
    }
}
