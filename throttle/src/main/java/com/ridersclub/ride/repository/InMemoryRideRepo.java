package com.ridersclub.ride.repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Ride;

@Repository
public class InMemoryRideRepo implements RideRepository {

    private final Map<String, Ride> rides = new ConcurrentHashMap<>();

    @Override
    public Ride save(Ride ride) {
        rides.put(ride.getRideUid().toString(), ride);
        return ride;
    }

    @Override
    public List<Ride> findAll() {
        return new ArrayList<>(rides.values());
    }

}
