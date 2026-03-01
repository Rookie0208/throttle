package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.GroupMember;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMember, Long> {
// Find all members in a group
    List<GroupMember> findById(String groupId);
    // Find specific member in a group
    Optional<GroupMember> findByGroup_IdAndUser_Id(String groupId, String userId);

    // Find all groups a user belongs to
    List<GroupMember> findByUser_Id(String userId);
}
