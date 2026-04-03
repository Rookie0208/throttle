package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.GroupMember;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMember, Long> {
     boolean existsByGroup_IdAndUser_Id(Long rideGroupId, Long userId);
     Optional<GroupMember> findByGroup_IdAndUser_Id(Long rideGroupId, Long userId);
     List<GroupMember> findByGroup_Id(Long rideGroupId);
     void deleteByGroup_IdAndUser_Id(Long rideGroupId, Long userId);
}
