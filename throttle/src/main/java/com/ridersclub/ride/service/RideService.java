package com.ridersclub.ride.service;

import java.nio.file.AccessDeniedException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.dto.request.RideSummaryRequest;
import com.ridersclub.ride.entity.GroupMember;
import com.ridersclub.ride.entity.GroupRole;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.Group;
import com.ridersclub.ride.entity.RideLocation;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.ride.entity.RideStats;
import com.ridersclub.ride.entity.RsvpStatus;
import com.ridersclub.ride.repository.GroupMemberRepository;
import com.ridersclub.ride.repository.GroupRepository;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.repository.RideStatsRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

@Service
public class RideService {

    @Autowired
    private RideRepository rideRepository;
    @Autowired
    private RideParticipantRepository participantRepo;
    @Autowired
    private RideStatsRepository statsRepo;
    @Autowired
    private GroupRepository groupRepository;
    @Autowired
    private GroupMemberRepository groupMemberRepository;
    @Autowired
    private UserRepository userRepository;

    public Ride createRide(CreateRideRequest request, String currentUserUUId) throws AccessDeniedException {
        Ride ride = new Ride();
        ride.setTitle(request.getTitle());
        ride.setDescription(request.getDescription());
        // ride.setRouteType(request.getRouteType());
        ride.setRideType(request.getRideType());
        ride.setStartTime(request.getStartTime());
        ride.setMaxRiders(request.getMaxRiders());
        ride.setVisibility(request.getVisibility());
        // ride.setRules(request.getRules());
        ride.setUuid(UUID.randomUUID().toString());
        ride.setCaptainId(currentUserUUId != null ? currentUserUUId : UserUtility.generateUUID().toString());

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
        
        User currentUser = userRepository.findByUuid(currentUserUUId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 3. Ownership
        ride.setCreatedBy(currentUser);

        if ("GROUP".equalsIgnoreCase(request.getRideType().name())) {

            Group group = new Group();
            group.setUuid(ride.getUuid().toString());
            group.setCreatedAt(LocalDateTime.now());
            group.setName(request.getTitle());
            group.setDescription(request.getDescription());
            group.setCreatedBy(currentUser);

            groupRepository.save(group);

            // 3️⃣ Add creator as ADMIN

            GroupMember admin = new GroupMember();
            admin.setGroup(group);
            admin.setUser(currentUser);
            admin.setRole(GroupRole.ADMIN);

            groupMemberRepository.save(admin);
            System.out.println("Group created with ID: " + group.getId() + " for Ride ID: " + ride.getUuid());
            System.out.println("Ride Group : " + group);
            System.out.println("Group Member : " + admin);

            ride.setGroup(group);
        } else { // solo ride
            Group group = new Group();
            group.setUuid(ride.getUuid().toString());
            group.setCreatedAt(LocalDateTime.now());
            group.setName(request.getTitle());
            group.setDescription(request.getDescription());
            group.setCreatedBy(currentUser);

            groupRepository.save(group);

            // 3️⃣ Add creator as ADMIN

            GroupMember admin = new GroupMember();
            admin.setGroup(group);
            admin.setUser(currentUser);
            admin.setRole(GroupRole.ADMIN);

            groupMemberRepository.save(admin);
            System.out.println("SOLO created with ID: " + group.getId() + " for Ride ID: " + ride.getUuid());
            System.out.println("Ride Group : " + group);
            System.out.println("Group Member : " + admin);
        }

        Ride saved = rideRepository.save(ride);
        participantRepo.save(new RideParticipant(saved, currentUser));
        System.out.println("Ride created with ID: " + saved.getUuid() + " and Captain ID: " + saved.getCaptainId());
        System.out.println("full ride details: " + ride);

        return saved;
    }

    public void join(String rideId, String userId) {

        Ride ride = rideRepository.findById(rideId)
                .orElseThrow(() -> new RuntimeException("Ride not found"));

        User user = userRepository.findByUuid(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (participantRepo.existsByRide_IdAndUser_Id(ride.getId(), user.getId()))
            throw new RuntimeException("Already joined");

        participantRepo.save(new RideParticipant(null, ride.getId(), user.getId(), LocalDateTime.now()));
    }

    public List<Ride> myRides(String userId) {

        List<RideParticipant> rideIds = participantRepo.findByUser_Id(userId);

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

        ride.setStatus(RsvpStatus.COMPLETED);
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
