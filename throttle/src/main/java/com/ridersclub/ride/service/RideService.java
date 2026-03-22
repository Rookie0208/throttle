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
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import org.springframework.transaction.annotation.Transactional;
import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.LocationType;
import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.common.enums.RideType;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.Status;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.dto.request.CreateSubGroupRequest;
import com.ridersclub.ride.dto.request.RideSummaryRequest;
import com.ridersclub.ride.dto.response.MyRidesResp;
import com.ridersclub.ride.dto.response.RideLocationResp;
import com.ridersclub.ride.dto.response.SubGroupResponse;
import com.ridersclub.ride.entity.GroupMember;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.ride.entity.RideLocation;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.ride.entity.RideRule;
import com.ridersclub.ride.entity.RideStats;
import com.ridersclub.ride.repository.GroupMemberRepository;
import com.ridersclub.ride.repository.RideGroupRepository;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.repository.RideStatsRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

@Service
@Transactional
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
        @Autowired
        private NotificationService notificationService;
        @Autowired
        private RideGroupRepository rideGroupRepository;
        @Autowired
        private GroupMemberRepository groupMemberRepository;

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
                start.setLocationType(LocationType.START);
                start.setSequence(1);
                start.setRide(ride);

                ride.addLocation(start);

                RideLocation end = new RideLocation();
                end.setName(request.getEndLocation().getName());
                end.setLatitude(request.getEndLocation().getLatitude());
                end.setLongitude(request.getEndLocation().getLongitude());
                end.setLocationType(LocationType.END);
                end.setSequence(2);
                end.setRide(ride);

                ride.addLocation(end);

                ride.setCreatedBy(currentUser);

                Ride saved = rideRepository.save(ride);
                participantRepo.save(new RideParticipant(saved, currentUser));
                logger.debug("Ride created with ID: " + saved.getUuid() + " and Captain ID: "
                                + saved.getCaptain().getId());
                logger.debug("full ride details: " + ride);

                if (saved.getRideType() == RideType.GROUP) {

                        RideGroup mainGroup = new RideGroup();
                        mainGroup.setUuid(UUID.randomUUID().toString());
                        mainGroup.setRide(saved);
                        mainGroup.setName(saved.getTitle() + " - Main Group");
                        mainGroup.setCreatedBy(currentUser);

                        RideGroup savedGroup = rideGroupRepository.save(mainGroup);

                        GroupMember captainMember = new GroupMember();
                        captainMember.setGroup(savedGroup);
                        captainMember.setUser(currentUser);
                        captainMember.setRole("ADMIN");

                        groupMemberRepository.save(captainMember);
                }

                notificationService.createAndSend(
                                currentUser.getId(),
                                "RIDE_CREATED",
                                "Ride Created",
                                "Your ride \"" + ride.getTitle() + "\" has been created successfully.",
                                saved.getId(),
                                "RIDE");

                System.out.println("notification published");

                return saved;
        }

        public RideGroup createSubGroup(CreateSubGroupRequest request, String userUuid) {

                User user = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                Ride ride = rideRepository.findByUuid(request.getRideUuid())
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                RideGroup mainGroup = rideGroupRepository
                                .findByRideAndParentGroupIsNull(ride)
                                .orElseThrow(() -> new RuntimeException("Main group not found"));

                RideGroup subGroup = new RideGroup();

                subGroup.setUuid(UUID.randomUUID().toString());
                subGroup.setName(request.getName());
                subGroup.setVisibility(request.getVisibility());
                subGroup.setMembersCanSendMessages(request.isMembersCanSendMessages());
                subGroup.setMembersCanAddMembers(request.isMembersCanAddMembers());
                subGroup.setParentGroup(mainGroup);
                subGroup.setRide(mainGroup.getRide());
                subGroup.setCreatedBy(user);

                rideGroupRepository.save(subGroup);
                notificationService.createAndSend(
                                user.getId(),
                                "RIDE_CREATED",
                                "Ride Created",
                                "Your ride \"" + ride.getTitle() + "\" has been created successfully.",
                                subGroup.getId(),
                                "RIDE");

                System.out.println("notification published");

                return subGroup;
        }

        public void join(String rideId, String userId) {

                Ride ride = rideRepository.findByUuid(rideId)
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                if (ride.getStatus() != Status.CREATED) {
                        throw new RuntimeException("Ride already started. Cannot join.");
                }

                long currentCount = participantRepo.countByRide_Id(ride.getId());

                if (currentCount >= ride.getMaxRiders()) {
                        throw new RuntimeException("Ride is full");
                }

                User user = userRepository.findByUuid(userId)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                if (participantRepo.existsByRide_IdAndUser_Id(ride.getId(), user.getId()))
                        throw new RuntimeException("Already joined");

                participantRepo.save(new RideParticipant(ride, user));

                // Notify captain that someone joined
                notificationService.createAndSend(
                                ride.getCreatedBy().getId(),
                                "RIDER_JOINED",
                                "New Rider Joined",
                                user.getFirstName() + " joined your ride \"" + ride.getTitle() + "\".",
                                ride.getId(),
                                "RIDE");
        }

        public List<MyRidesResp> myRides(String userId) {

                User currUser = userRepository.findByUuid(userId)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                List<Ride> rides = participantRepo
                                .findByUser_Id(currUser.getId())
                                .stream()
                                .map(RideParticipant::getRide)
                                .toList();

                List<MyRidesResp> myRides = rides.stream()
                                .map(r -> MyRidesResp.builder()
                                                .uuid(r.getUuid())
                                                .title(r.getTitle())
                                                .description(r.getDescription())
                                                .rideType(r.getRideType())
                                                .routeType(r.getRouteType())
                                                .startTime(r.getStartTime())
                                                .endTime(r.getEndTime())
                                                .locations(r.getLocations().stream()
                                                                .map(loc -> RideLocationResp.builder()
                                                                                .name(loc.getName())
                                                                                .latitude(loc.getLatitude())
                                                                                .longitude(loc.getLongitude())
                                                                                .locationType(loc.getLocationType())
                                                                                .sequence(loc.getSequence())
                                                                                .build())
                                                                .toList())
                                                .maxRiders(r.getMaxRiders())
                                                .createdByUuid(r.getCreatedBy().getUuid())
                                                .captainUuid(r.getCaptain() != null ? r.getCaptain().getUuid() : null)
                                                .visibility(r.getVisibility())
                                                .status(r.getStatus())
                                                .createdAt(r.getCreatedAt().toLocalDateTime())
                                                .updatedAt(r.getUpdatedAt().toLocalDateTime())
                                                .build())
                                .toList();

                return myRides;
        }

        @Transactional(readOnly = true)
        public Ride getRideById(String id) {
                return rideRepository.findByUuid(id).orElseThrow(() -> new RuntimeException("Ride not found"));
        }

        @Transactional(readOnly = true)
        public List<RideParticipant> participants(String rideId) {
                Ride ride = rideRepository.findByUuid(rideId)
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                return participantRepo.findByRide_Id(ride.getId());

        }

        public void complete(String rideId, String userId) {

                Ride ride = rideRepository.findByUuid(rideId)
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                RideParticipant participant = participantRepo
                                .findByRide_IdAndUser_Uuid(rideId, userId)
                                .orElseThrow(() -> new RuntimeException("Not part of ride"));

                if (participant.getRole() != Role.CAPTAIN) {
                        throw new RuntimeException("Only captain can complete ride");
                }

                ride.setStatus(Status.COMPLETED);
                rideRepository.save(ride);
        }

        public void addStats(String rideId, String userId, RideSummaryRequest req) {

                statsRepo.save(new RideStats(null, rideId, userId,
                                req.getDistanceKm(), req.getDurationMinutes(), req.getAvgSpeed()));
        }

        // ------------- DASHBOARD ------------------
        @Transactional(readOnly = true)
        public Map<String, Object> dashboard(String userId) {

                List<RideStats> stats = statsRepo.findByUserId(userId);

                double totalDistance = stats.stream().mapToDouble(RideStats::getDistanceKm).sum();
                long totalDuration = stats.stream().mapToLong(RideStats::getDurationMinutes).sum();

                return Map.of(
                                "totalRides", stats.size(),
                                "totalDistance", totalDistance,
                                "totalDuration", totalDuration);
        }

        public List<SubGroupResponse> getSubGroups(String rideUuid) {

                List<RideGroup> groups = rideGroupRepository.findSubGroupsByRideUuid(rideUuid);

                return groups.stream()
                                .map(group -> SubGroupResponse.builder()
                                                .uuid(group.getUuid())
                                                .name(group.getName())
                                                .rideUuid(group.getRide().getUuid())
                                                .parentGroupUuid(
                                                                group.getParentGroup() != null
                                                                                ? group.getParentGroup().getUuid()
                                                                                : null)
                                                .visibility(group.getVisibility())
                                                .membersCanSendMessages(group.getMembersCanSendMessages())
                                                .membersCanAddMembers(group.getMembersCanAddMembers())
                                                .createdByUuid(group.getCreatedBy().getUuid())
                                                .createdAt(group.getCreatedAt())
                                                .build())
                                .toList();
        }
}