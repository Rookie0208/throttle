package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Group;

@Repository
public interface GroupRepository extends JpaRepository<Group, Long> {
    Optional<Group> findById(String rideId);

    Optional<Group> findByUuid(String uuid);

    // Group save(Group group);

    List<Group> findByIdIn(List<String> rideIds);

    // void deleteByRideId(String rideId);
}
