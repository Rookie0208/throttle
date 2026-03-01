package com.ridersclub.ride.service;

import java.nio.file.AccessDeniedException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.dto.request.RideSummaryRequest;
import com.ridersclub.ride.entity.GroupMember;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.ride.entity.RideLocation;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.ride.entity.RideStats;
import com.ridersclub.ride.entity.RideStatus;
import com.ridersclub.ride.repository.GroupMemberRepository;
import com.ridersclub.ride.repository.RideGroupRepository;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.repository.RideStatsRepository;

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
    private RideGroupRepository groupRepository;
    @Autowired
    private GroupMemberRepository groupMemberRepository;

    public Ride createRide(CreateRideRequest request, String currentUserUUId) throws AccessDeniedException {
        Ride ride = new Ride();
        ride.setTitle(request.getTitle());
        ride.setDescription(request.getDescription());
        ride.setRouteType(request.getRouteType());
        ride.setRideType(request.getRideType());
        ride.setStartTime(request.getStartTime());
        ride.setMaxRiders(request.getMaxRiders());
        ride.setVisibility(request.getVisibility());
        ride.setRules(request.getRules());
        ride.setRideUid(UUID.randomUUID());
        ride.setCaptainId(currentUserUUId != null ? currentUserUUId : UserUtility.generateUUID().toString());

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
        ride.setCreatedBy(currentUserUUId != null ? currentUserUUId : UserUtility.generateUUID().toString());

        Ride saved = rideRepository.save(ride);
        participantRepo.save(new RideParticipant(saved.getId(), null,
                currentUserUUId != null ? currentUserUUId : UserUtility.generateUUID().toString(),
                LocalDateTime.now()));
        logger.info("Ride created with ID: {} and Captain ID: {}", saved.getRideUid(), saved.getCaptainId());
        logger.debug("full ride details: {}", ride);

        if ("GROUP".equalsIgnoreCase(request.getRideType().name())) {

            RideGroup group = new RideGroup();
            group.setRideId(ride.getRideUid().toString());
            group.setCreatedAt(LocalDateTime.now());

            groupRepository.save(group);

            // 3️⃣ Add creator as ADMIN
            GroupMember admin = new GroupMember();
            admin.setGroupId(group.getId());
            admin.setUserId(currentUserUUId);
            admin.setRole("ADMIN");

            groupMemberRepository.save(admin);
            logger.info("Group created with ID: {} for Ride ID: {}", group.getId(), ride.getRideUid());
            logger.debug("Ride Group : {}", group);
            logger.debug("Group Member : {}", admin);
        }

        return saved;
    }

    public void join(String rideId, String userId) {

        Ride ride = rideRepository.findById(rideId)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        if (participantRepo.exists(rideId, userId))
            throw new RuntimeException("Already joined");

        participantRepo.save(new RideParticipant(null, rideId, userId, LocalDateTime.now()));
    }

    public List<Ride> myRides(String userId) {

        List<String> rideIds = participantRepo.findByUserId(userId)
                .stream().map(RideParticipant::getRideId).toList();

        return rideRepository.findAll().stream()
                .filter(r -> rideIds.contains(r.getId()))
                .toList();
    }

    public List<RideParticipant> participants(String rideId) {
        return participantRepo.findByRideId(rideId);
    }

    public void complete(String rideId) {

        Ride ride = rideRepository.findById(rideId)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        ride.setStatus(RideStatus.COMPLETED);
        rideRepository.save(ride);
    }

    public void addStats(String rideId, String userId, RideSummaryRequest req) {

        statsRepo.save(new RideStats(null, rideId, userId,
                req.getDistanceKm(), req.getDurationMinutes(), req.getAvgSpeed()));
    }

    public Map<String, Object> dashboard(String userId) {

        List<RideStats> stats = statsRepo.findByUserId(userId);

        double totalDistance = stats.stream().mapToDouble(RideStats::getDistanceKm).sum();
        long totalDuration = stats.stream().mapToLong(RideStats::getDurationMinutes).sum();

        return Map.of(
                "totalRides", stats.size(),
                "totalDistance", totalDistance,
                "totalDuration", totalDuration);
    }
}
