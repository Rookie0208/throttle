package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.ClubSubgroupMember;

@Repository
public interface ClubSubgroupMemberRepository extends JpaRepository<ClubSubgroupMember, Long> {
    List<ClubSubgroupMember> findBySubgroup_Id(Long subgroupId);
    Optional<ClubSubgroupMember> findBySubgroup_IdAndUser_Id(Long subgroupId, Long userId);
    boolean existsBySubgroup_IdAndUser_Id(Long subgroupId, Long userId);
    long countBySubgroup_Id(Long subgroupId);
    void deleteBySubgroup_IdAndUser_Id(Long subgroupId, Long userId);
}
