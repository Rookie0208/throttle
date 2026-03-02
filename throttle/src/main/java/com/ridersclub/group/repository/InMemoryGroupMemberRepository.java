package com.ridersclub.group.repository;

import java.util.*;
import java.util.stream.Collectors;

import org.springframework.stereotype.Repository;

import com.ridersclub.group.entity.Group;
import com.ridersclub.group.entity.GroupMember;
import com.ridersclub.user.entity.User;

@Repository
public class InMemoryGroupMemberRepository implements GroupMemberRepository {

    private final Map<Long, GroupMember> membersById = new HashMap<>();
private final Map<Long, List<Long>> groupToMemberIds = new HashMap<>();
private final Map<Long, List<Long>> userToMemberIds = new HashMap<>();

    // Save or update member
    @Override
    public GroupMember save(GroupMember member) {

        membersById.put(member.getId(), member);

        groupToMemberIds
                .computeIfAbsent(member.getGroup().getId(), k -> new ArrayList<>())
                .add(member.getId());

        userToMemberIds
                .computeIfAbsent(member.getUser().getId(), k -> new ArrayList<>())
                .add(member.getId());

        return member;
    }

    // Find members by group
    public List<GroupMember> findByGroupId(String groupId) {
        List<Long> ids = groupToMemberIds.getOrDefault(groupId, new ArrayList<>());
        return ids.stream()
                .map(membersById::get)
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }

    // Find by user entity
    @Override
    public List<GroupMember> findByUser(User user) {
        List<Long> ids = userToMemberIds.getOrDefault(user.getId(), new ArrayList<>());
        return ids.stream()
                .map(membersById::get)
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }

    // Check if user already exists in group
    @Override
    public boolean existsByGroupAndUser(Group group, User user) {

        return findByGroupId(group.getId()).stream()
                .anyMatch(member ->
                        member.getUser().getId().equals(user.getId())
                );
    }

    // Delete member by groupId and userId
    public void deleteByGroupIdAndUserId(String groupId, String userId) {

        List<GroupMember> members = findByGroupId(groupId);

        members.stream()
                .filter(m -> m.getUser().getId().equals(userId))
                .forEach(m -> {
                    membersById.remove(m.getId());
                    groupToMemberIds.getOrDefault(groupId, new ArrayList<>())
                            .remove(m.getId());
                    userToMemberIds.getOrDefault(userId, new ArrayList<>())
                            .remove(m.getId());
                });
    }

    @Override
    public Optional<com.ridersclub.group.entity.GroupMember> findByGroupIdAndUserId(String groupId, String userId) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'findByGroupIdAndUserId'");
    }

    @Override
    public List<com.ridersclub.group.entity.GroupMember> findByUserId(String userId) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'findByUserId'");
    }

    @Override
    public GroupMember save(com.ridersclub.ride.entity.GroupMember admin) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'save'");
    }

    @Override
    public List<GroupMember> findByGroupId(Long groupId) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'findByGroupId'");
    }
}