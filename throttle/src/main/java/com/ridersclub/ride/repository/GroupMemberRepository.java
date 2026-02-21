package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.GroupMember;

@Repository
public interface GroupMemberRepository extends org.springframework.data.repository.Repository<GroupMember, Long> {
// Find all members in a group
    List<GroupMember> findByGroupId(String groupId);
GroupMember save(GroupMember member);
    // Find specific member in a group
    Optional<GroupMember> findByGroupIdAndUserId(String groupId, String userId);

    // Delete member from a group
    void deleteByGroupIdAndUserId(String groupId, String userId);

    // Find all groups a user belongs to
    List<GroupMember> findByUserId(String userId);
}
