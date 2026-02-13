package com.ridersclub.ride.repository;

import java.util.List;

import com.ridersclub.ride.entity.RideParticipant;

public interface RideParticipantRepository extends org.springframework.data.repository.Repository<RideParticipant, Long> { 
    RideParticipant save(RideParticipant rp);

    boolean exists(String rideId, String userId);

    List<RideParticipant> findByRideId(String rideId);

    List<RideParticipant> findByUserId(String userId);

    
}