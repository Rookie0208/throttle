package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.RideGroup;

@Repository
public interface RideGroupRepository extends org.springframework.data.repository.Repository<RideGroup, Long> {
    Optional<RideGroup> findByRideId(String rideId);
RideGroup save(RideGroup group);
    List<RideGroup> findByRideIdIn(List<String> rideIds);

    void deleteByRideId(String rideId);
}
