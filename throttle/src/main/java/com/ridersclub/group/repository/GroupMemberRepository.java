package com.ridersclub.group.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.ridersclub.group.entity.Group;
import com.ridersclub.group.entity.GroupMember;
import com.ridersclub.user.entity.User;

@Repository
public interface GroupMemberRepository extends org.springframework.data.repository.Repository<GroupMember, Long> {
// Find all members in a group
    List<GroupMember> findByGroupId(Long groupId);
    GroupMember save(com.ridersclub.ride.entity.GroupMember admin);
    Optional<GroupMember> findByGroupIdAndUserId(String groupId, String userId);

    void deleteByGroupIdAndUserId(String groupId, String userId);

    List<GroupMember> findByUserId(String userId);
    List<com.ridersclub.group.entity.GroupMember> findByUser(User user);
    boolean existsByGroupAndUser(Group group, User user);
    GroupMember save(GroupMember member);
}
