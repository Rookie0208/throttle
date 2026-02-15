package com.ridersclub.ride.repository;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.RideParticipant;

@Repository
public class InMemoryRideParticipantRepository implements RideParticipantRepository {
    private final List<RideParticipant> list = new CopyOnWriteArrayList<>();

    @Override
    public RideParticipant save(RideParticipant rp) {
        rp.setUserId(UUID.randomUUID().toString());
        list.add(rp);
        return rp;
    }

    @Override
    public boolean exists(String rideId, String userId) {
        return list.stream().anyMatch(p ->
                p.getRideId().equals(rideId) && p.getUserId().equals(userId));
    }

    @Override
    public List<RideParticipant> findByRideId(String rideId) {
        return list.stream().filter(p -> p.getRideId().equals(rideId)).toList();
    }

    @Override
    public List<RideParticipant> findByUserId(String userId) {
        return list.stream().filter(p -> p.getUserId().equals(userId)).toList();
    }

}
