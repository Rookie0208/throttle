package com.ridersclub.ride.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.RideLiveLocation;

@Repository
public interface RideLiveLocationRepository extends JpaRepository<RideLiveLocation, Long> {
    Optional<RideLiveLocation> findTopByRide_IdAndUser_IdOrderByRecordedAtDesc(Long rideId, Long userId);
}
