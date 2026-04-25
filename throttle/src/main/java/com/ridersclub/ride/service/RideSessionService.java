package com.ridersclub.ride.service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import lombok.extern.slf4j.Slf4j;

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
                .currentUserTimeToMeetingSeconds(resolveTimeToMeetingSeconds(actor))
                .meetingPoint(mainGroup.getPreRideMeetingPoint())
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
                .checkpoints(checkpoints)
                .participants(participantDtos)
                .build();
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
        rideRepository.save(ride);

        createSystemGroupMessage(
                ride,
                actor.getUser(),
                "SOS " + resolution.toLowerCase() + " by " + formatUserName(actor.getUser()) + ".");

        RideSessionResponse session = getRideSession(rideUuid, actorUserUuid);
        publishSessionUpdate(rideUuid);
        return session;
    }

    public void syncCompletionState(Ride ride) {
        List<RideParticipant> participants = participantRepository.findByRide_IdAndRsvpStatusNot(ride.getId(), Status.EXITED);
        LocalDateTime completedAt = LocalDateTime.now();
        for (RideParticipant participant : participants) {
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

    private void ensureActorCanManage(RideParticipant actor) {
        if (!isRideManager(actor.getRole())) {
            throw new RuntimeException("Only captain/admin can manage the ride");
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
        if (participant.getPartialStartedAt() == null || participant.getArrivedAtStartAt() == null) {
            return null;
        }
        return Duration.between(participant.getPartialStartedAt(), participant.getArrivedAtStartAt()).getSeconds();
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
                checkpoints.add(RideSessionCheckpointResponse.builder()
                        .sequence(i)
                        .title(rideCheckpoints.get(i).getName())
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
