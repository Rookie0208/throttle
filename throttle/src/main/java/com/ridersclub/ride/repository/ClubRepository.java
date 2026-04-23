package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Club;

@Repository
public interface ClubRepository extends JpaRepository<Club, Long> {
    Optional<Club> findByUuid(String uuid);
    boolean existsByNameIgnoreCase(String name);
    List<Club> findTop20ByNameContainingIgnoreCaseOrTitleContainingIgnoreCaseOrderByCreatedAtDesc(String name, String title);
}
