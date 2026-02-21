package com.ridersclub.ride.repository;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.GroupMember;

@Repository
public class InMemoryGroupMemberRepository implements GroupMemberRepository {
private final Map<String, GroupMember> membersById = new HashMap<>();
    private final Map<String, List<String>> groupToMemberIds = new HashMap<>();
    private final Map<String, List<String>> userToMemberIds = new HashMap<>();

    // Save or update member
    public GroupMember save(GroupMember member) {
        membersById.put(member.getId(), member);

        groupToMemberIds.computeIfAbsent(member.getGroupId(), k -> new ArrayList<>()).add(member.getId());
        userToMemberIds.computeIfAbsent(member.getUserId(), k -> new ArrayList<>()).add(member.getId());

        return member;
    }

    // Find members by groupId
    public List<GroupMember> findByGroupId(String groupId) {
        List<String> ids = groupToMemberIds.getOrDefault(groupId, new ArrayList<>());
        return ids.stream().map(membersById::get).collect(Collectors.toList());
    }

    // Find specific member in group
    public Optional<GroupMember> findByGroupIdAndUserId(String groupId, String userId) {
        return findByGroupId(groupId).stream()
                .filter(m -> m.getUserId().equals(userId))
                .findFirst();
    }

    // Delete member by groupId and userId
    public void deleteByGroupIdAndUserId(String groupId, String userId) {
        List<GroupMember> members = findByGroupId(groupId);
        members.stream()
                .filter(m -> m.getUserId().equals(userId))
                .forEach(m -> {
                    membersById.remove(m.getId());
                    groupToMemberIds.getOrDefault(groupId, new ArrayList<>()).remove(m.getId());
                    userToMemberIds.getOrDefault(userId, new ArrayList<>()).remove(m.getId());
                });
    }

    // Find all groups a user belongs to
    public List<GroupMember> findByUserId(String userId) {
        List<String> ids = userToMemberIds.getOrDefault(userId, new ArrayList<>());
        return ids.stream().map(membersById::get).collect(Collectors.toList());
    }

}
