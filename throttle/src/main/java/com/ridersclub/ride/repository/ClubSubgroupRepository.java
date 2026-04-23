package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.ClubSubgroup;

@Repository
public interface ClubSubgroupRepository extends JpaRepository<ClubSubgroup, Long> {
    Optional<ClubSubgroup> findByUuid(String uuid);
    List<ClubSubgroup> findByClub_IdOrderByCreatedAtDesc(Long clubId);
    boolean existsByClub_IdAndNameIgnoreCase(Long clubId, String name);
}
