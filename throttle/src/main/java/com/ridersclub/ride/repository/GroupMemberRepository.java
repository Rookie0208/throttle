package com.ridersclub.ride.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.GroupMember;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMember, Long> {
     boolean existsByGroup_IdAndUser_Id(Long rideGroupId, Long userId);
    
}
