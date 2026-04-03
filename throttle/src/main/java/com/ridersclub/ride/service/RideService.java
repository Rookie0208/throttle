package com.ridersclub.ride.service;

import java.nio.file.AccessDeniedException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
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
import com.ridersclub.common.enums.UuidPrefix;
import com.ridersclub.common.enums.Visibility;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.dto.request.CreateSubGroupRequest;
import com.ridersclub.ride.dto.request.RideSummaryRequest;
import com.ridersclub.ride.dto.request.UpdatePreRideInfoRequest;
import com.ridersclub.ride.dto.response.GroupMemberResponse;
import com.ridersclub.ride.dto.response.MyRidesResp;
import com.ridersclub.ride.dto.response.PreRideInfoResponse;
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

                if (request.getStartTime() == null || !request.getStartTime().isAfter(LocalDateTime.now())) {
                        throw new IllegalArgumentException("Ride start time must be in the future");
                }

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

                ride.setUuid(UserUtility.generateUUID(UuidPrefix.RIDE.name()));
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
                        mainGroup.setUuid(UserUtility.generateUUID(UuidPrefix.GROUP.name()));
                        mainGroup.setRide(saved);
                        mainGroup.setName(saved.getTitle() + " - Main Group");
                        mainGroup.setCreatedBy(currentUser);

                        RideGroup savedGroup = rideGroupRepository.save(mainGroup);

                        GroupMember captainMember = new GroupMember();
                        captainMember.setGroup(savedGroup);
                        captainMember.setUser(currentUser);
                        captainMember.setRole("ADMIN");

                        groupMemberRepository.save(captainMember);
                        createTeamMembersSubGroup(saved, savedGroup, currentUser);
                } else {
                        RideGroup mainGroup = new RideGroup();
                        mainGroup.setUuid(UserUtility.generateUUID(UuidPrefix.GROUP.name()));
                        mainGroup.setRide(saved);
                        mainGroup.setName(saved.getTitle() + " - SOLO Ride");
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

        private RideGroup createTeamMembersSubGroup(Ride ride, RideGroup mainGroup, User creator) {
                RideGroup teamMembersGroup = new RideGroup();
                teamMembersGroup.setUuid(UserUtility.generateUUID(UuidPrefix.GROUP.name()));
                teamMembersGroup.setRide(ride);
                teamMembersGroup.setParentGroup(mainGroup);
                teamMembersGroup.setName("Team members");
                teamMembersGroup.setCreatedBy(creator);
                teamMembersGroup.setVisibility(Visibility.PRIVATE);
                teamMembersGroup.setMembersCanSendMessages(true);
                teamMembersGroup.setMembersCanAddMembers(false);

                RideGroup savedTeamMembersGroup = rideGroupRepository.save(teamMembersGroup);

                GroupMember creatorMember = new GroupMember();
                creatorMember.setGroup(savedTeamMembersGroup);
                creatorMember.setUser(creator);
                creatorMember.setRole("ADMIN");
                groupMemberRepository.save(creatorMember);

                return savedTeamMembersGroup;
        }

        public SubGroupResponse createSubGroup(CreateSubGroupRequest request, String userUuid) {

                User user = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                Ride ride = rideRepository.findByUuid(request.getRideUuid())
                                .orElseThrow(() -> new RuntimeException("Ride not found"));

                RideParticipant actor = participantRepo.findByRide_UuidAndUser_Uuid(ride.getUuid(), userUuid)
                                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));

                if (!isSubGroupManager(actor.getRole().name())) {
                        throw new RuntimeException("Only captain/admin can create subgroups");
                }

                if (request.getVisibility() == null) {
                        throw new RuntimeException("Please select subgroup visibility");
                }

                RideGroup mainGroup = rideGroupRepository
                                .findByRideAndParentGroupIsNull(ride)
                                .orElseThrow(() -> new RuntimeException("Main group not found"));

                RideGroup subGroup = new RideGroup();

                subGroup.setUuid(UserUtility.generateUUID(UuidPrefix.GROUP.name()));
                subGroup.setName(request.getName());
                subGroup.setVisibility(request.getVisibility());
                subGroup.setMembersCanSendMessages(request.isMembersCanSendMessages());
                subGroup.setMembersCanAddMembers(request.isMembersCanAddMembers());
                subGroup.setAdminsApproveMembers(request.isAdminsApproveMembers());
                subGroup.setParentGroup(mainGroup);
                subGroup.setRide(mainGroup.getRide());
                subGroup.setCreatedBy(user);

                RideGroup savedGroup = rideGroupRepository.save(subGroup);
                addGroupMemberIfMissing(subGroup, user, "ADMIN");
                if (request.getMemberUuids() != null) {
                        for (String memberUuid : request.getMemberUuids()) {
                                if (memberUuid == null || memberUuid.isBlank()) {
                                        continue;
                                }

                                User member = userRepository.findByUuid(memberUuid)
                                                .orElseThrow(() -> new RuntimeException("User not found"));

                                if (!participantRepo.existsByRide_IdAndUser_Id(ride.getId(), member.getId())) {
                                        throw new RuntimeException("Only ride members can be added to a subgroup");
                                }

                                addGroupMemberIfMissing(savedGroup, member, "RIDER");
                        }
                }

                notificationService.createAndSend(
                                user.getId(),
                                "SUBGROUP_CREATED",
                                "Subgroup Created",
                                "Your subgroup \"" + subGroup.getName() + "\" has been created successfully.",
                                savedGroup.getId(),
                                "RIDE");

                System.out.println("notification published");

                return buildSubGroupResponse(savedGroup, user);
        }

        private void addGroupMemberIfMissing(RideGroup group, User user, String role) {
                if (groupMemberRepository.existsByGroup_IdAndUser_Id(group.getId(), user.getId())) {
                        return;
                }

                GroupMember member = new GroupMember();
                member.setGroup(group);
                member.setUser(user);
                member.setRole(role);
                groupMemberRepository.save(member);
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
                                                .groupUuid(
                                                        rideGroupRepository.findByRideAndParentGroupIsNull(r)
                                                                .orElseThrow(() -> new RuntimeException("RideGroup not found"))
                                                                .getUuid())
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
                                                .createdByName(
                                                                ((r.getCreatedBy().getFirstName() != null
                                                                                ? r.getCreatedBy().getFirstName()
                                                                                : "")
                                                                                + " "
                                                                                + (r.getCreatedBy().getLastName() != null
                                                                                                ? r.getCreatedBy().getLastName()
                                                                                                : ""))
                                                                                                .trim())
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

        public List<SubGroupResponse> getSubGroups(String rideUuid, String userUuid) {

                Ride ride = rideRepository.findByUuid(rideUuid)
                                .orElseThrow(() -> new RuntimeException("Ride not found"));
                List<RideGroup> groups = rideGroupRepository.findSubGroupsByRideUuid(rideUuid);
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));

                if (!participantRepo.existsByRide_IdAndUser_Id(ride.getId(), currentUser.getId())) {
                        throw new RuntimeException("You are not part of this ride");
                }

                return groups.stream()
                                .filter(group -> group.getVisibility() == Visibility.PUBLIC
                                                || groupMemberRepository.existsByGroup_IdAndUser_Id(
                                                                group.getId(), currentUser.getId()))
                                .map(group -> buildSubGroupResponse(group, currentUser))
                                .toList();
        }

        @Transactional(readOnly = true)
        public SubGroupResponse getGroupDetails(String groupUuid, String userUuid) {
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, currentUser);
                return buildSubGroupResponse(group, currentUser);
        }

        @Transactional(readOnly = true)
        public List<GroupMemberResponse> getGroupMembers(String groupUuid, String userUuid) {
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, currentUser);

                return groupMemberRepository.findByGroup_Id(group.getId())
                                .stream()
                                .map(member -> GroupMemberResponse.builder()
                                                .userUuid(member.getUser().getUuid())
                                                .firstName(member.getUser().getFirstName())
                                                .lastName(member.getUser().getLastName())
                                                .profileImage(member.getUser().getProfileImage())
                                                .role(member.getRole())
                                                .joinedAt(member.getJoinedAt())
                                                .build())
                                .toList();
        }

        public void updateGroupMemberRole(String groupUuid, String targetUserUuid, String role, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                GroupMember actor = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElseThrow(() -> new RuntimeException("You are not part of this subgroup"));

                if (!isSubGroupManager(actor.getRole())) {
                        throw new RuntimeException("Only captain/admin can update subgroup roles");
                }

                User targetUser = userRepository.findByUuid(targetUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                GroupMember target = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), targetUser.getId())
                                .orElseThrow(() -> new RuntimeException("Member not found in this subgroup"));

                target.setRole(role.toUpperCase());
                groupMemberRepository.save(target);
        }

        public void removeGroupMember(String groupUuid, String targetUserUuid, String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                GroupMember actor = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElseThrow(() -> new RuntimeException("You are not part of this subgroup"));

                if (!isSubGroupManager(actor.getRole())) {
                        throw new RuntimeException("Only captain/admin can remove subgroup members");
                }

                User targetUser = userRepository.findByUuid(targetUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                GroupMember target = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), targetUser.getId())
                                .orElseThrow(() -> new RuntimeException("Member not found in this subgroup"));

                if (isSubGroupManager(target.getRole())) {
                        throw new RuntimeException("Captain/Admin cannot be removed from subgroup");
                }

                groupMemberRepository.delete(target);
        }

        private RideGroup getAccessibleGroup(String groupUuid, User currentUser) {
                RideGroup group = rideGroupRepository.findByUuid(groupUuid)
                                .orElseThrow(() -> new RuntimeException("Group not found"));

                boolean isRideParticipant = participantRepo.existsByRide_IdAndUser_Id(
                                group.getRide().getId(),
                                currentUser.getId());

                boolean canAccess = (group.getVisibility() == Visibility.PUBLIC && isRideParticipant)
                                || groupMemberRepository.existsByGroup_IdAndUser_Id(group.getId(), currentUser.getId());

                if (!canAccess) {
                        throw new RuntimeException("You are not allowed to access this subgroup");
                }

                return group;
        }

        private SubGroupResponse buildSubGroupResponse(RideGroup group, User currentUser) {
                GroupMember currentMembership = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), currentUser.getId())
                                .orElse(null);
                String createdByName = ((group.getCreatedBy().getFirstName() != null
                                ? group.getCreatedBy().getFirstName()
                                : "")
                                + " "
                                + (group.getCreatedBy().getLastName() != null
                                                ? group.getCreatedBy().getLastName()
                                                : ""))
                                                                .trim();

                return SubGroupResponse.builder()
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
                                .adminsApproveMembers(Boolean.TRUE.equals(group.getAdminsApproveMembers()))
                                .createdByUuid(group.getCreatedBy().getUuid())
                                .createdByName(createdByName)
                                .myRole(currentMembership != null ? currentMembership.getRole() : null)
                                .memberCount(groupMemberRepository.findByGroup_Id(group.getId()).size())
                                .preRideInfo(buildPreRideInfoMap(group))
                                .createdAt(group.getCreatedAt())
                                .build();
        }

        public void addGroupMembers(String groupUuid, List<String> memberUuids, String actorUserUuid) {
                if (memberUuids == null || memberUuids.isEmpty()) {
                        throw new RuntimeException("Select at least one member to add");
                }

                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                if (!canAddMembers(group, actorUser)) {
                        throw new RuntimeException("You do not have permission to add members to this subgroup");
                }

                List<String> uniqueMemberUuids = memberUuids.stream()
                                .filter(uuid -> uuid != null && !uuid.isBlank())
                                .distinct()
                                .toList();

                for (String memberUuid : uniqueMemberUuids) {
                        User member = userRepository.findByUuid(memberUuid)
                                        .orElseThrow(() -> new RuntimeException("User not found"));

                        if (!participantRepo.existsByRide_IdAndUser_Id(group.getRide().getId(), member.getId())) {
                                throw new RuntimeException("Only ride members can be added to a subgroup");
                        }

                        addGroupMemberIfMissing(group, member, "RIDER");
                }
        }

        public PreRideInfoResponse getPreRideInfo(String groupUuid, String userUuid) {
                User currentUser = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, currentUser);
                return buildPreRideInfoResponse(group);
        }

        public PreRideInfoResponse updatePreRideInfo(
                        String groupUuid,
                        UpdatePreRideInfoRequest request,
                        String actorUserUuid) {
                User actorUser = userRepository.findByUuid(actorUserUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = getAccessibleGroup(groupUuid, actorUser);

                GroupMember actorMembership = groupMemberRepository
                                .findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElse(null);
                boolean actorIsRideManager = participantRepo.findByRide_UuidAndUser_Uuid(
                                group.getRide().getUuid(),
                                actorUserUuid)
                                .map(participant -> isSubGroupManager(participant.getRole().name()))
                                .orElse(false);

                if (!(actorIsRideManager
                                || (actorMembership != null && isSubGroupManager(actorMembership.getRole())))) {
                        throw new RuntimeException("Only captain/admin can update pre-ride info");
                }

                group.setPreRideMeetingPoint(trimToNull(request.getMeetingPoint()));
                group.setPreRideFuelStops(trimToNull(request.getFuelStops()));
                group.setPreRideCheckpoints(joinList(request.getCheckpointList()));
                group.setPreRideRules(joinList(request.getRuleList()));
                group.setPreRideNotes(trimToNull(request.getNotes()));
                group.setPreRideUpdatedAt(LocalDateTime.now());

                RideGroup savedGroup = rideGroupRepository.save(group);
                return buildPreRideInfoResponse(savedGroup);
        }

        private PreRideInfoResponse buildPreRideInfoResponse(RideGroup group) {
                return PreRideInfoResponse.builder()
                                .title(group.getRide().getTitle())
                                .description(group.getRide().getDescription())
                                .rideType(group.getRide().getRideType())
                                .routeType(group.getRide().getRouteType())
                                .maxRiders(group.getRide().getMaxRiders())
                                .visibility(group.getVisibility())
                                .startTime(group.getRide().getStartTime())
                                .meetingPoint(group.getPreRideMeetingPoint())
                                .fuelStops(group.getPreRideFuelStops())
                                .checkpointList(splitList(group.getPreRideCheckpoints()))
                                .ruleList(splitList(group.getPreRideRules()))
                                .notes(group.getPreRideNotes())
                                .updatedAt(group.getPreRideUpdatedAt())
                                .build();
        }

        private Map<String, Object> buildPreRideInfoMap(RideGroup group) {
                PreRideInfoResponse response = buildPreRideInfoResponse(group);
                Map<String, Object> map = new LinkedHashMap<>();
                map.put("title", response.getTitle());
                map.put("description", response.getDescription());
                map.put("rideType", response.getRideType());
                map.put("routeType", response.getRouteType());
                map.put("maxRiders", response.getMaxRiders());
                map.put("visibility", response.getVisibility());
                map.put("startTime", response.getStartTime());
                map.put("meetingPoint", response.getMeetingPoint());
                map.put("fuelStops", response.getFuelStops());
                map.put("checkpointList", response.getCheckpointList());
                map.put("ruleList", response.getRuleList());
                map.put("notes", response.getNotes());
                map.put("updatedAt", response.getUpdatedAt());
                return map;
        }

        private List<String> splitList(String value) {
                if (value == null || value.isBlank()) {
                        return List.of();
                }
                return Arrays.stream(value.split(","))
                                .map(String::trim)
                                .filter(item -> !item.isEmpty())
                                .toList();
        }

        private String joinList(List<String> values) {
                if (values == null) {
                        return null;
                }
                return values.stream()
                                .filter(item -> item != null && !item.isBlank())
                                .map(String::trim)
                                .distinct()
                                .collect(Collectors.joining(", "));
        }

        private String trimToNull(String value) {
                if (value == null) {
                        return null;
                }
                String trimmed = value.trim();
                return trimmed.isEmpty() ? null : trimmed;
        }

        private boolean canAddMembers(RideGroup group, User actorUser) {
                GroupMember actorMembership = groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), actorUser.getId())
                                .orElse(null);
                if (actorMembership != null && isSubGroupManager(actorMembership.getRole())) {
                        return true;
                }

                boolean actorIsRideManager = participantRepo.findByRide_UuidAndUser_Uuid(
                                group.getRide().getUuid(),
                                actorUser.getUuid())
                                .map(participant -> isSubGroupManager(participant.getRole().name()))
                                .orElse(false);
                if (actorIsRideManager) {
                        return true;
                }

                if (!Boolean.TRUE.equals(group.getMembersCanAddMembers())) {
                        return false;
                }

                if (Boolean.TRUE.equals(group.getAdminsApproveMembers())) {
                        return false;
                }

                return actorMembership != null
                                || (group.getVisibility() == Visibility.PUBLIC
                                                && participantRepo.existsByRide_IdAndUser_Id(
                                                                group.getRide().getId(),
                                                                actorUser.getId()));
        }

        private boolean isSubGroupManager(String role) {
                if (role == null) {
                        return false;
                }
                String normalizedRole = role.trim().toUpperCase();
                return normalizedRole.equals("CAPTAIN") || normalizedRole.equals("ADMIN");
        }
}
