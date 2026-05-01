package com.ridersclub.ride.service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import lombok.extern.slf4j.Slf4j;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.LocationType;
import com.ridersclub.common.enums.MessageType;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.RideParticipantState;
import com.ridersclub.common.enums.Status;
import com.ridersclub.common.enums.UuidPrefix;
import com.ridersclub.message.entity.GroupMessage;
import com.ridersclub.message.repository.GroupMessageRepository;
import com.ridersclub.ride.dto.request.RideLocationUpdateRequest;
import com.ridersclub.ride.dto.request.RideSosRequest;
import com.ridersclub.ride.dto.request.RideSosResolutionRequest;
import com.ridersclub.ride.dto.response.RideBroadcastResponse;
import com.ridersclub.ride.dto.response.RideParticipantDto;
import com.ridersclub.ride.dto.response.RideSessionCheckpointResponse;
import com.ridersclub.ride.dto.response.RideSessionResponse;
import com.ridersclub.ride.dto.response.RideSessionUpdateEvent;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.ride.entity.RideLiveLocation;
import com.ridersclub.ride.entity.RideLocation;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.ride.repository.RideGroupRepository;
import com.ridersclub.ride.repository.RideLiveLocationRepository;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.user.entity.User;

@Slf4j
@Service
@Transactional
public class RideSessionService {

    private final RideRepository rideRepository;
    private final RideParticipantRepository participantRepository;
    private final RideGroupRepository rideGroupRepository;
    private final RideLiveLocationRepository rideLiveLocationRepository;
    private final GroupMessageRepository groupMessageRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public RideSessionService(
            RideRepository rideRepository,
            RideParticipantRepository participantRepository,
            RideGroupRepository rideGroupRepository,
            RideLiveLocationRepository rideLiveLocationRepository,
            GroupMessageRepository groupMessageRepository,
            SimpMessagingTemplate messagingTemplate) {
        this.rideRepository = rideRepository;
        this.participantRepository = participantRepository;
        this.rideGroupRepository = rideGroupRepository;
        this.rideLiveLocationRepository = rideLiveLocationRepository;
        this.groupMessageRepository = groupMessageRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional(readOnly = true)
    public RideSessionResponse getRideSession(String rideUuid, String actorUserUuid) {
        Ride ride = getRide(rideUuid);
        RideParticipant actor = getActiveParticipant(rideUuid, actorUserUuid);
        RideGroup mainGroup = rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                .orElseThrow(() -> new RuntimeException("Main group not found"));

        List<RideParticipant> participants = participantRepository.findByRide_IdAndRsvpStatusNot(
                ride.getId(),
                Status.EXITED);

        List<RideParticipantDto> participantDtos = participants.stream()
                .sorted(Comparator.comparing(
                        participant -> formatUserName(participant.getUser()).toLowerCase()))
                .map(participant -> mapParticipantDto(ride, participant))
                .toList();

        List<RideSessionCheckpointResponse> checkpoints = buildCheckpoints(ride, mainGroup);
        List<RideBroadcastResponse> broadcasts = groupMessageRepository
                .findByGroup_IdAndMessageTypeOrderByCreatedAtAsc(mainGroup.getId(), MessageType.SYSTEM)
                .stream()
                .filter(message -> isBroadcastMessage(message.getMessage()))
                .map(message -> RideBroadcastResponse.builder()
                        .message(message.getMessage())
                        .createdAt(message.getCreatedAt())
                        .build())
                .toList();

        return RideSessionResponse.builder()
                .rideUuid(ride.getUuid())
                .title(ride.getTitle())
                .rideStatus(ride.getStatus().name())
                .scheduledStartTime(ride.getStartTime())
                .rideStartedAt(ride.getRideStartedAt())
                .rideCompletedAt(ride.getRideCompletedAt())
                .captainUuid(ride.getCaptain() != null ? ride.getCaptain().getUuid() : null)
                .captainName(ride.getCaptain() != null ? formatUserName(ride.getCaptain()) : null)
                .currentUserUuid(actor.getUser().getUuid())
                .currentUserCaptain(isRideManager(actor.getRole()))
                .currentUserRole(actor.getRole().name())
                .currentUserState(resolveRideState(actor, ride).name())
                .currentUserRideStartedAt(actor.getPartialStartedAt())
                .currentUserArrivedAtStartAt(actor.getArrivedAtStartAt())
                .currentUserReturnStartTime(actor.getReturnStartedAt())
                .currentUserReturnEndTime(actor.getReturnCompletedAt())
                .currentUserTimeToMeetingSeconds(resolveTimeToMeetingSeconds(actor))
                .currentUserGroupRideDurationSeconds(resolveGroupRideDurationSeconds(actor, ride))
                .currentUserReturnRideDurationSeconds(resolveReturnRideDurationSeconds(actor))
                .currentUserTotalRideDurationSeconds(resolveTotalRideDurationSeconds(actor, ride))
                .meetingPoint(mainGroup.getPreRideMeetingPoint())
                .meetingPointLocation(readJsonMap(mainGroup.getPreRideMeetingPointLocation()))
                .fuelStops(mainGroup.getPreRideFuelStops())
                .currentCheckpointIndex(ride.getCurrentCheckpointIndex() != null ? ride.getCurrentCheckpointIndex() : 0)
                .latestBroadcastMessage(ride.getLatestBroadcastMessage())
                .latestBroadcastAt(ride.getLatestBroadcastAt())
                .activeSosMessage(ride.getActiveSosMessage())
                .activeSosAt(ride.getActiveSosAt())
                .activeSosRaisedByName(
                        ride.getActiveSosRaisedBy() != null ? formatUserName(ride.getActiveSosRaisedBy()) : null)
                .activeSosRaisedByUuid(
                        ride.getActiveSosRaisedBy() != null ? ride.getActiveSosRaisedBy().getUuid() : null)
                .activeSosResolution(ride.getActiveSosResolution())
                .activeSosResolvedAt(ride.getActiveSosResolvedAt())
                .activeSosResolvedByName(
                        ride.getActiveSosResolvedBy() != null ? formatUserName(ride.getActiveSosResolvedBy()) : null)
                .activeSosResolvedByUuid(
                        ride.getActiveSosResolvedBy() != null ? ride.getActiveSosResolvedBy().getUuid() : null)
                .participantsCount(participantDtos.size())
                .enRouteCount((int) participants.stream()
                        .filter(participant -> resolveRideState(participant, ride) == RideParticipantState.EN_ROUTE)
                        .count())
                .atStartCount((int) participants.stream()
                        .filter(participant -> resolveRideState(participant, ride) == RideParticipantState.AT_START_POINT)
                        .count())
                .inRideCount((int) participants.stream()
                        .filter(participant -> resolveRideState(participant, ride) == RideParticipantState.IN_RIDE)
                        .count())
                .returnRideStartedCount((int) participants.stream()
                        .filter(participant -> resolveRideState(participant, ride) == RideParticipantState.RETURN_RIDE_STARTED)
                        .count())
                .returnRideCompletedCount((int) participants.stream()
                        .filter(participant -> resolveRideState(participant, ride) == RideParticipantState.RETURN_RIDE_COMPLETED)
                        .count())
                .broadcasts(broadcasts)
                .checkpoints(checkpoints)
                .participants(participantDtos)
                .build();
    }

    private Map<String, Object> readJsonMap(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return objectMapper.readValue(value, new TypeReference<Map<String, Object>>() {
            });
        } catch (Exception e) {
            log.warn("Failed to parse ride session location JSON: {}", e.getMessage());
            return null;
        }
    }

    public RideSessionResponse partialStart(String rideUuid, String actorUserUuid) {
        Ride ride = getRide(rideUuid);
        RideParticipant participant = getActiveParticipant(rideUuid, actorUserUuid);
        ensureRideMutable(ride);

        participant.setRideState(RideParticipantState.EN_ROUTE);
        LocalDateTime now = LocalDateTime.now();
        if (participant.getPartialStartedAt() == null) {
            participant.setPartialStartedAt(now);
        }
        participant.setStateUpdatedAt(now);
        participantRepository.save(participant);

        if (ride.getStatus() == Status.CREATED || ride.getStatus() == Status.SCHEDULED) {
            ride.setStatus(Status.PARTIAL_STARTED);
            rideRepository.save(ride);
        }

        createSystemGroupMessage(ride, participant.getUser(), formatUserName(participant.getUser()) + " is en route.");
        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    public RideSessionResponse markArrivedAtStart(String rideUuid, String actorUserUuid) {
        Ride ride = getRide(rideUuid);
        RideParticipant participant = getActiveParticipant(rideUuid, actorUserUuid);
        ensureRideMutable(ride);

        participant.setRideState(RideParticipantState.AT_START_POINT);
        LocalDateTime now = LocalDateTime.now();
        if (participant.getPartialStartedAt() == null) {
            participant.setPartialStartedAt(now);
        }
        if (participant.getArrivedAtStartAt() == null) {
            participant.setArrivedAtStartAt(now);
        }
        participant.setStateUpdatedAt(now);
        participantRepository.save(participant);

        if (ride.getStatus() == Status.CREATED
                || ride.getStatus() == Status.SCHEDULED
                || ride.getStatus() == Status.PARTIAL_STARTED) {
            ride.setStatus(Status.READY_TO_START);
            rideRepository.save(ride);
        }

        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    public RideSessionResponse startRide(String rideUuid, String actorUserUuid) {
        Ride ride = getRide(rideUuid);
        RideParticipant actor = getActiveParticipant(rideUuid, actorUserUuid);
        ensureActorCanManage(actor);
        ensureRideMutable(ride);

        ride.setStatus(Status.ACTIVE);
        if (ride.getRideStartedAt() == null) {
            ride.setRideStartedAt(LocalDateTime.now());
        }
        if (ride.getCurrentCheckpointIndex() == null) {
            ride.setCurrentCheckpointIndex(0);
        }
        rideRepository.save(ride);

        List<RideParticipant> participants = participantRepository.findByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED);
        for (RideParticipant participant : participants) {
            if (resolveRideState(participant, ride) != RideParticipantState.DROPPED) {
                participant.setRideState(RideParticipantState.IN_RIDE);
                participant.setStateUpdatedAt(LocalDateTime.now());
            }
        }
        participantRepository.saveAll(participants);

        createSystemGroupMessage(ride, actor.getUser(), "Ride started by " + formatUserName(actor.getUser()) + ".");
        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    public RideSessionResponse updateLocation(String rideUuid, String actorUserUuid, RideLocationUpdateRequest request) {
        Ride ride = getRide(rideUuid);
        RideParticipant participant = getActiveParticipant(rideUuid, actorUserUuid);
        User user = participant.getUser();

        RideLiveLocation location = new RideLiveLocation();
        location.setRide(ride);
        location.setUser(user);
        location.setLatitude(request.getLatitude());
        location.setLongitude(request.getLongitude());
        location.setRecordedAt(LocalDateTime.now());
        rideLiveLocationRepository.save(location);

        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    public RideSessionResponse startReturnRide(String rideUuid, String actorUserUuid) {
        Ride ride = getRide(rideUuid);
        RideParticipant participant = getActiveParticipant(rideUuid, actorUserUuid);
        ensureRideCompletedForReturn(ride);
        ensureParticipantEligibleForReturn(participant);

        if (participant.getReturnStartedAt() != null
                || resolveRideState(participant, ride) == RideParticipantState.RETURN_RIDE_STARTED
                || resolveRideState(participant, ride) == RideParticipantState.RETURN_RIDE_COMPLETED) {
            return getRideSession(rideUuid, actorUserUuid);
        }

        LocalDateTime rideCompletedAt = ride.getRideCompletedAt();
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime returnStartedAt = rideCompletedAt != null && now.isBefore(rideCompletedAt)
                ? rideCompletedAt
                : now;

        participant.setReturnStartedAt(returnStartedAt);
        participant.setRideState(RideParticipantState.RETURN_RIDE_STARTED);
        participant.setStateUpdatedAt(returnStartedAt);
        participantRepository.save(participant);

        createSystemGroupMessage(
                ride,
                participant.getUser(),
                formatUserName(participant.getUser()) + " started their return ride.");

        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    public RideSessionResponse endReturnRide(String rideUuid, String actorUserUuid) {
        Ride ride = getRide(rideUuid);
        RideParticipant participant = getActiveParticipant(rideUuid, actorUserUuid);
        ensureRideCompletedForReturn(ride);
        ensureParticipantEligibleForReturn(participant);

        if (participant.getReturnCompletedAt() != null
                || resolveRideState(participant, ride) == RideParticipantState.RETURN_RIDE_COMPLETED) {
            return getRideSession(rideUuid, actorUserUuid);
        }

        if (participant.getReturnStartedAt() == null) {
            throw new RuntimeException("Return ride has not been started");
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime returnCompletedAt = now.isBefore(participant.getReturnStartedAt())
                ? participant.getReturnStartedAt()
                : now;

        participant.setReturnCompletedAt(returnCompletedAt);
        participant.setReturnRideDurationSeconds(
                Duration.between(participant.getReturnStartedAt(), returnCompletedAt).getSeconds());
        participant.setRideState(RideParticipantState.RETURN_RIDE_COMPLETED);
        participant.setStateUpdatedAt(returnCompletedAt);
        participantRepository.save(participant);

        createSystemGroupMessage(
                ride,
                participant.getUser(),
                formatUserName(participant.getUser()) + " completed their return ride.");

        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    public RideSessionResponse advanceCheckpoint(String rideUuid, String actorUserUuid) {
        Ride ride = getRide(rideUuid);
        RideParticipant actor = getActiveParticipant(rideUuid, actorUserUuid);
        ensureActorCanManage(actor);

        List<RideSessionCheckpointResponse> checkpoints = buildCheckpoints(
                ride,
                rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                        .orElseThrow(() -> new RuntimeException("Main group not found")));

        if (checkpoints.isEmpty()) {
            throw new RuntimeException("No checkpoints configured for this ride");
        }

        int currentIndex = ride.getCurrentCheckpointIndex() != null ? ride.getCurrentCheckpointIndex() : 0;
        if (currentIndex < checkpoints.size() - 1) {
            ride.setCurrentCheckpointIndex(currentIndex + 1);
            rideRepository.save(ride);
        }

        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    public RideSessionResponse sendSos(String rideUuid, String actorUserUuid, RideSosRequest request) {
        Ride ride = getRide(rideUuid);
        RideParticipant participant = getActiveParticipant(rideUuid, actorUserUuid);
        ensureRideMutable(ride);

        LocalDateTime now = LocalDateTime.now();
        String message = request.getMessage().trim();

        ride.setActiveSosMessage(message);
        ride.setActiveSosAt(now);
        ride.setActiveSosRaisedBy(participant.getUser());
        ride.setActiveSosResolution(null);
        ride.setActiveSosResolvedAt(null);
        ride.setActiveSosResolvedBy(null);
        rideRepository.save(ride);

        createSystemGroupMessage(
                ride,
                participant.getUser(),
                "SOS: " + message + " from " + formatUserName(participant.getUser()) + ".");

        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    public RideSessionResponse resolveSos(
            String rideUuid,
            String actorUserUuid,
            RideSosResolutionRequest request) {
        Ride ride = getRide(rideUuid);
        RideParticipant actor = getActiveParticipant(rideUuid, actorUserUuid);
        ensureActorCanManage(actor);

        if (ride.getActiveSosMessage() == null || ride.getActiveSosMessage().isBlank()) {
            throw new RuntimeException("No active SOS to resolve");
        }

        String resolution = request.getResolution().trim().toUpperCase();
        LocalDateTime now = LocalDateTime.now();
        ride.setActiveSosResolution(resolution);
        ride.setActiveSosResolvedAt(now);
        ride.setActiveSosResolvedBy(actor.getUser());

        if ("ACCEPTED".equals(resolution)) {
            ride.setLatestBroadcastMessage("SOS accepted by " + formatUserName(actor.getUser()) + ".");
            ride.setLatestBroadcastAt(now);
            clearActiveSos(ride);
        }

        rideRepository.save(ride);

        createSystemGroupMessage(
                ride,
                actor.getUser(),
                "SOS " + resolution.toLowerCase() + " by " + formatUserName(actor.getUser()) + ".");

        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    private void clearActiveSos(Ride ride) {
        ride.setActiveSosMessage(null);
        ride.setActiveSosAt(null);
        ride.setActiveSosRaisedBy(null);
        ride.setActiveSosResolution(null);
        ride.setActiveSosResolvedAt(null);
        ride.setActiveSosResolvedBy(null);
    }

    private boolean isBroadcastMessage(String message) {
        if (message == null || message.isBlank()) {
            return false;
        }

        return message.startsWith("Captain broadcast:")
                || message.startsWith("SOS accepted by ");
    }

    public void syncCompletionState(Ride ride) {
        List<RideParticipant> participants = participantRepository.findByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED);
        LocalDateTime completedAt = ride.getRideCompletedAt() != null ? ride.getRideCompletedAt() : LocalDateTime.now();
        for (RideParticipant participant : participants) {
            if (participant.getRideState() == RideParticipantState.DROPPED
                    || participant.getRideState() == RideParticipantState.RETURN_RIDE_STARTED
                    || participant.getRideState() == RideParticipantState.RETURN_RIDE_COMPLETED) {
                continue;
            }
            participant.setRideState(RideParticipantState.COMPLETED);
            participant.setStateUpdatedAt(completedAt);
        }
        participantRepository.saveAll(participants);
    }

    public void publishSessionUpdate(String rideUuid) {
        try {
            messagingTemplate.convertAndSend(
                    "/topic/rides/" + rideUuid,
                    RideSessionUpdateEvent.builder()
                            .rideUuid(rideUuid)
                            .eventType("SESSION_UPDATED")
                            .occurredAt(LocalDateTime.now())
                            .build());
        } catch (Exception ignored) {
            // Socket delivery is best-effort. The persisted session state remains the source of truth.
        }
    }

    private Ride getRide(String rideUuid) {
        return rideRepository.findByUuid(rideUuid)
                .orElseThrow(() -> new RuntimeException("Ride not found"));
    }

    private RideParticipant getActiveParticipant(String rideUuid, String actorUserUuid) {
        return participantRepository.findByRide_UuidAndUser_UuidAndRsvpStatusNot(
                rideUuid,
                actorUserUuid,
                Status.EXITED)
                .orElseThrow(() -> new RuntimeException("You are not part of this ride"));
    }

    private void ensureRideMutable(Ride ride) {
        if (ride.getStatus() == Status.COMPLETED || ride.getStatus() == Status.CANCELLED) {
            throw new RuntimeException("This ride can no longer be updated");
        }
    }

    private void ensureRideCompletedForReturn(Ride ride) {
        if (ride.getStatus() != Status.COMPLETED || ride.getRideCompletedAt() == null) {
            throw new RuntimeException("Return ride can only start after the group ride is completed");
        }
    }

    private void ensureActorCanManage(RideParticipant actor) {
        if (!isRideManager(actor.getRole())) {
            throw new RuntimeException("Only captain/admin can manage the ride");
        }
    }

    private void ensureParticipantEligibleForReturn(RideParticipant participant) {
        if (participant.getRideState() == RideParticipantState.DROPPED) {
            throw new RuntimeException("Dropped riders cannot start a return ride");
        }
    }

    private boolean isRideManager(Role role) {
        return role == Role.CAPTAIN || role == Role.ADMIN || role == Role.CO_CAPTAIN;
    }

    private RideParticipantState resolveRideState(RideParticipant participant, Ride ride) {
        if (participant.getRideState() != null) {
            return participant.getRideState();
        }
        if (ride.getStatus() == Status.ACTIVE) {
            return RideParticipantState.IN_RIDE;
        }
        if (ride.getStatus() == Status.COMPLETED) {
            return RideParticipantState.COMPLETED;
        }
        return RideParticipantState.JOINED;
    }

    private Long resolveTimeToMeetingSeconds(RideParticipant participant) {
        return resolveElapsedSeconds(participant.getPartialStartedAt(), participant.getArrivedAtStartAt());
    }

    private Long resolveGroupRideDurationSeconds(RideParticipant participant, Ride ride) {
        if (ride.getRideStartedAt() == null) {
            return null;
        }

        LocalDateTime groupRideEnd = ride.getRideCompletedAt();
        if (groupRideEnd == null && ride.getStatus() == Status.ACTIVE) {
            groupRideEnd = LocalDateTime.now();
        }

        return resolveElapsedSeconds(ride.getRideStartedAt(), groupRideEnd);
    }

    private Long resolveReturnRideDurationSeconds(RideParticipant participant) {
        if (participant.getReturnRideDurationSeconds() != null) {
            return participant.getReturnRideDurationSeconds();
        }

        return resolveElapsedSeconds(participant.getReturnStartedAt(), participant.getReturnCompletedAt());
    }

    private Long resolveTotalRideDurationSeconds(RideParticipant participant, Ride ride) {
        Long rideToMeeting = resolveTimeToMeetingSeconds(participant);
        Long groupRide = resolveGroupRideDurationSeconds(participant, ride);
        Long returnRide = resolveReturnRideDurationSeconds(participant);

        long total = 0L;
        boolean hasSegment = false;

        if (rideToMeeting != null) {
            total += rideToMeeting;
            hasSegment = true;
        }
        if (groupRide != null) {
            total += groupRide;
            hasSegment = true;
        }
        if (returnRide != null) {
            total += returnRide;
            hasSegment = true;
        }

        return hasSegment ? total : null;
    }

    private Long resolveElapsedSeconds(LocalDateTime startedAt, LocalDateTime completedAt) {
        if (startedAt == null || completedAt == null) {
            return null;
        }
        if (completedAt.isBefore(startedAt)) {
            return 0L;
        }
        return Duration.between(startedAt, completedAt).getSeconds();
    }

    private RideParticipantDto mapParticipantDto(Ride ride, RideParticipant participant) {
        Optional<RideLiveLocation> latestLocation = rideLiveLocationRepository.findTopByRide_IdAndUser_IdOrderByRecordedAtDesc(
                ride.getId(),
                participant.getUser().getId());

        return RideParticipantDto.builder()
                .userUuid(participant.getUser().getUuid())
                .riderId(participant.getUser().getRiderId())
                .firstName(participant.getUser().getFirstName())
                .lastName(participant.getUser().getLastName())
                .profileImage(participant.getUser().getProfileImage())
                .role(participant.getRole().name())
                .rsvpStatus(participant.getRsvpStatus().name())
                .participantState(resolveRideState(participant, ride).name())
                .lastLatitude(latestLocation.map(RideLiveLocation::getLatitude).orElse(null))
                .lastLongitude(latestLocation.map(RideLiveLocation::getLongitude).orElse(null))
                .lastLocationUpdatedAt(latestLocation.map(RideLiveLocation::getRecordedAt).orElse(null))
                .joinedAt(participant.getJoinedAt())
                .rideStartedAt(participant.getPartialStartedAt())
                .arrivedAtStartAt(participant.getArrivedAtStartAt())
                .returnStartTime(participant.getReturnStartedAt())
                .returnEndTime(participant.getReturnCompletedAt())
                .rideToMeetingDurationSeconds(resolveTimeToMeetingSeconds(participant))
                .groupRideDurationSeconds(resolveGroupRideDurationSeconds(participant, ride))
                .returnRideDurationSeconds(resolveReturnRideDurationSeconds(participant))
                .totalRideDurationSeconds(resolveTotalRideDurationSeconds(participant, ride))
                .build();
    }

    private List<RideSessionCheckpointResponse> buildCheckpoints(Ride ride, RideGroup mainGroup) {
        List<RideSessionCheckpointResponse> checkpoints = new ArrayList<>();

        List<RideLocation> rideCheckpoints = ride.getLocations().stream()
                .filter(location -> location.getLocationType() == LocationType.CHECKPOINT)
                .sorted(Comparator.comparing(location -> location.getSequence() == null ? Integer.MAX_VALUE : location.getSequence()))
                .toList();

        if (!rideCheckpoints.isEmpty()) {
            int currentIndex = ride.getCurrentCheckpointIndex() != null ? ride.getCurrentCheckpointIndex() : 0;
            for (int i = 0; i < rideCheckpoints.size(); i++) {
                RideLocation checkpoint = rideCheckpoints.get(i);
                checkpoints.add(RideSessionCheckpointResponse.builder()
                        .sequence(i)
                        .title(checkpoint.getName())
                        .latitude(checkpoint.getLatitude())
                        .longitude(checkpoint.getLongitude())
                        .checkpointStatus(resolveCheckpointStatus(i, currentIndex))
                        .build());
            }
            return checkpoints;
        }

        List<Map<String, Object>> checkpointLocations = readJsonList(mainGroup.getPreRideCheckpointLocations());
        if (!checkpointLocations.isEmpty()) {
            int currentIndex = ride.getCurrentCheckpointIndex() != null ? ride.getCurrentCheckpointIndex() : 0;
            for (int i = 0; i < checkpointLocations.size(); i++) {
                Map<String, Object> checkpoint = checkpointLocations.get(i);
                checkpoints.add(RideSessionCheckpointResponse.builder()
                        .sequence(i)
                        .title((checkpoint.get("name") != null ? checkpoint.get("name") : "Checkpoint").toString())
                        .latitude(asDouble(checkpoint.get("latitude")))
                        .longitude(asDouble(checkpoint.get("longitude")))
                        .checkpointStatus(resolveCheckpointStatus(i, currentIndex))
                        .build());
            }
            return checkpoints;
        }

        String rawCheckpoints = mainGroup.getPreRideCheckpoints();
        if (rawCheckpoints == null || rawCheckpoints.isBlank()) {
            return checkpoints;
        }

        String[] names = rawCheckpoints.split(",");
        int currentIndex = ride.getCurrentCheckpointIndex() != null ? ride.getCurrentCheckpointIndex() : 0;
        for (int i = 0; i < names.length; i++) {
            String title = names[i].trim();
            if (title.isEmpty()) {
                continue;
            }
            checkpoints.add(RideSessionCheckpointResponse.builder()
                    .sequence(checkpoints.size())
                    .title(title)
                    .checkpointStatus(resolveCheckpointStatus(checkpoints.size(), currentIndex))
                    .build());
        }

        return checkpoints;
    }

    private List<Map<String, Object>> readJsonList(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(value, new TypeReference<List<Map<String, Object>>>() {
            });
        } catch (Exception e) {
            log.warn("Failed to parse ride session checkpoint JSON: {}", e.getMessage());
            return List.of();
        }
    }

    private Double asDouble(Object value) {
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        if (value == null) {
            return null;
        }
        try {
            return Double.parseDouble(value.toString());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String resolveCheckpointStatus(int checkpointIndex, int currentIndex) {
        if (checkpointIndex < currentIndex) {
            return "COMPLETED";
        }
        if (checkpointIndex == currentIndex) {
            return "CURRENT";
        }
        return "UPCOMING";
    }

    private String formatUserName(User user) {
        String firstName = user.getFirstName() != null ? user.getFirstName().trim() : "";
        String lastName = user.getLastName() != null ? user.getLastName().trim() : "";
        String fullName = (firstName + " " + lastName).trim();
        return fullName.isEmpty() ? "Someone" : fullName;
    }

    private void createSystemGroupMessage(Ride ride, User actor, String message) {
        RideGroup mainGroup = rideGroupRepository.findByRideAndParentGroupIsNull(ride)
                .orElseThrow(() -> new RuntimeException("Main group not found"));
        groupMessageRepository.save(GroupMessage.builder()
                .uuid(UserUtility.generateUUID(UuidPrefix.CHAT.name()))
                .sender(actor)
                .group(mainGroup)
                .message(message)
                .messageType(MessageType.SYSTEM)
                .edited(false)
                .build());
    }
}
