package com.ridersclub.ride.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Ride;

@Repository
public interface RideRepository extends JpaRepository<Ride, Long> {
    Optional<Ride> findByUuid(String uuid);

    public java.util.List<Ride> findAll();

    // Fetch up to 3 recent completed rides for a given list of ride IDs
    java.util.List<Ride> findTop3ByIdInAndStatusOrderByStartTimeDesc(java.util.List<Long> rideIds,
            com.ridersclub.common.enums.Status status);

    // Fetch the next upcoming planned ride for a given list of ride IDs
    Optional<Ride> findFirstByIdInAndStatusAndStartTimeAfterOrderByStartTimeAsc(java.util.List<Long> rideIds,
            com.ridersclub.common.enums.Status status, java.time.LocalDateTime now);
}
