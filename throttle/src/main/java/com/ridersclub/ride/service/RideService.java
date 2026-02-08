package com.ridersclub.ride.service;

import java.nio.file.AccessDeniedException;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideLocation;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.user.entity.User;


@Service
public class RideService {

    @Autowired
    private RideRepository rideRepository;

    public Ride createRide(CreateRideRequest request, User currentUser) throws AccessDeniedException {
        // 1. Authorization
        if (!currentUser.hasRole("CAPTAIN") && !currentUser.hasRole("ADMIN")) {
            throw new AccessDeniedException("You are not allowed to create rides");
        }
        Ride ride = new Ride();
        ride.setTitle(request.getTitle());
        ride.setDescription(request.getDescription());
        ride.setRouteType(request.getRouteType());
        ride.setStartTime(request.getStartTime());
        ride.setMaxRiders(request.getMaxRiders());
        ride.setVisibility(request.getVisibility());
        ride.setRules(request.getRules());
        ride.setRideUid(UUID.randomUUID());

        RideLocation start = new RideLocation();
        start.setName(request.getStartLocation().getName());
        start.setLatitude(request.getStartLocation().getLatitude());
        start.setLongitude(request.getStartLocation().getLongitude());

        RideLocation end = new RideLocation();
        end.setName(request.getEndLocation().getName());
        end.setLatitude(request.getEndLocation().getLatitude());
        end.setLongitude(request.getEndLocation().getLongitude());
        ride.setStartLocation(start);
        ride.setEndLocation(end);

        // 3. Ownership
        ride.setCreatedBy(currentUser.getUuid());

        return rideRepository.save(ride);
    }

}
