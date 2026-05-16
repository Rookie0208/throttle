package com.ridersclub.ride.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.RideStats;

@Repository
public interface RideStatsRepository extends JpaRepository<RideStats, Long> {
    List<RideStats> findByUserId(String userId);
    java.util.Optional<RideStats> findByRideIdAndUserId(String rideId, String userId);
}
