package com.ridersclub.ride.service;

import java.nio.file.AccessDeniedException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.Status;
import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.dto.request.RideSummaryRequest;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideLocation;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.ride.entity.RideRule;
import com.ridersclub.ride.entity.RideStats;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.repository.RideStatsRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

@Service
public class RideService {
    private static final Logger logger = LoggerFactory.getLogger(RideService.class);

    @Autowired
    private RideRepository rideRepository;
    @Autowired
    private RideParticipantRepository participantRepo;
    @Autowired
    private RideStatsRepository statsRepo;
    @Autowired
    private UserRepository userRepository;

    public Ride createRide(CreateRideRequest request, String currentUserUUId) throws AccessDeniedException {
        User currentUser = userRepository.findByUuid(currentUserUUId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Ride ride = new Ride();
        ride.setTitle(request.getTitle());
        ride.setDescription(request.getDescription());
        ride.setRouteType(request.getRouteType());
        ride.setRideType(request.getRideType());
        ride.setStartTime(request.getStartTime());
        ride.setMaxRiders(request.getMaxRiders());
        ride.setVisibility(request.getVisibility());
        ride.setStatus(Status.SCHEDULED);

        List<RideRule> rideRules = new ArrayList<>();
        for (int i = 0; i < request.getRules().size(); i++) {

            RideRule rule = new RideRule(request.getRules().get(i));
            rule.setRide(ride);
            rule.setCreatedBy(currentUser);
            rule.setRuleOrder(i);

            rideRules.add(rule);
        }
        ride.setRules(rideRules);
        
        ride.setUuid(UUID.randomUUID().toString());
        ride.setCaptain(currentUser);

        RideLocation start = new RideLocation();
        start.setName(request.getStartLocation().getName());
        start.setLatitude(request.getStartLocation().getLatitude());
        start.setLongitude(request.getStartLocation().getLongitude());

        RideLocation end = new RideLocation();
        end.setName(request.getEndLocation().getName());
        end.setLatitude(request.getEndLocation().getLatitude());
        end.setLongitude(request.getEndLocation().getLongitude());
        ride.setStartLocation(start.toString());
        ride.setEndLocation(end.toString());

        ride.setStartLat(request.getStartLocation().getLatitude());
        ride.setStartLng(request.getStartLocation().getLongitude());
        ride.setEndLat(request.getEndLocation().getLatitude());
        ride.setEndLng(request.getEndLocation().getLongitude());

        ride.setCreatedBy(currentUser);

        Ride saved = rideRepository.save(ride);
        participantRepo.save(new RideParticipant(saved, currentUser));
        logger.debug("Ride created with ID: " + saved.getUuid() + " and Captain ID: " + saved.getCaptain().getId());
        logger.debug("full ride details: " + ride);

        return saved;
    }

    public void join(String rideId, String userId) {

        Ride ride = rideRepository.findById(rideId)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        User user = userRepository.findByUuid(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (participantRepo.existsByRide_IdAndUser_Id(ride.getId(), user.getId()))
            throw new RuntimeException("Already joined");

        participantRepo.save(new RideParticipant(ride, user));
    }

    public List<Ride> myRides(String userId) {

        List<Ride> rideIds = participantRepo.findRidesByUserId(userId);
        // List<RideParticipant> rides = participantRepo.findByUserUUID(userId);

        return rideRepository.findAll().stream()
                .filter(r -> rideIds.contains(r.getId()))
                .toList();
    }

    public List<RideParticipant> participants(String rideId) {
        return participantRepo.findByRide_Id(rideId);
    }

    public void complete(String rideId) {

        Ride ride = rideRepository.findById(rideId)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        ride.setStatus(Status.COMPLETED);
        rideRepository.save(ride);
    }

    public void addStats(String rideId, String userId, RideSummaryRequest req) {

        statsRepo.save(new RideStats(null, rideId, userId,
                req.getDistanceKm(), req.getDurationMinutes(), req.getAvgSpeed()));
    }

    public Map<String, Object> dashboard(String userId) {

        List<RideStats> stats = statsRepo.findByUser_Id(userId);

        double totalDistance = stats.stream().mapToDouble(RideStats::getDistanceKm).sum();
        long totalDuration = stats.stream().mapToLong(RideStats::getDurationMinutes).sum();

        return Map.of(
                "totalRides", stats.size(),
                "totalDistance", totalDistance,
                "totalDuration", totalDuration);
    }
}