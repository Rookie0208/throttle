package com.ridersclub.ride.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
import com.ridersclub.ride.dto.response.RideParticipantDto;
import com.ridersclub.ride.dto.response.RideSessionCheckpointResponse;
import com.ridersclub.ride.dto.response.RideSessionResponse;
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

@Service
@Transactional
public class RideSessionService {

    private final RideRepository rideRepository;
    private final RideParticipantRepository participantRepository;
    private final RideGroupRepository rideGroupRepository;
    private final RideLiveLocationRepository rideLiveLocationRepository;
    private final GroupMessageRepository groupMessageRepository;

    public RideSessionService(
            RideRepository rideRepository,
            RideParticipantRepository participantRepository,
            RideGroupRepository rideGroupRepository,
            RideLiveLocationRepository rideLiveLocationRepository,
            GroupMessageRepository groupMessageRepository) {
        this.rideRepository = rideRepository;
        this.participantRepository = participantRepository;
        this.rideGroupRepository = rideGroupRepository;
        this.rideLiveLocationRepository = rideLiveLocationRepository;
        this.groupMessageRepository = groupMessageRepository;
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
                .currentUserCaptain(isRideManager(actor.getRole()))
                .currentUserRole(actor.getRole().name())
                .currentUserState(resolveRideState(actor, ride).name())
                .meetingPoint(mainGroup.getPreRideMeetingPoint())
                .fuelStops(mainGroup.getPreRideFuelStops())
                .currentCheckpointIndex(ride.getCurrentCheckpointIndex() != null ? ride.getCurrentCheckpointIndex() : 0)
                .latestBroadcastMessage(ride.getLatestBroadcastMessage())
                .latestBroadcastAt(ride.getLatestBroadcastAt())
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
        participant.setPartialStartedAt(LocalDateTime.now());
        participant.setStateUpdatedAt(LocalDateTime.now());
        participantRepository.save(participant);

        if (ride.getStatus() == Status.CREATED || ride.getStatus() == Status.SCHEDULED) {
            ride.setStatus(Status.PARTIAL_STARTED);
            rideRepository.save(ride);
        }

        createSystemGroupMessage(ride, participant.getUser(), formatUserName(participant.getUser()) + " is en route.");
        return getRideSession(rideUuid, actorUserUuid);
    }

    public RideSessionResponse markArrivedAtStart(String rideUuid, String actorUserUuid) {
        Ride ride = getRide(rideUuid);
        RideParticipant participant = getActiveParticipant(rideUuid, actorUserUuid);
        ensureRideMutable(ride);

        participant.setRideState(RideParticipantState.AT_START_POINT);
        participant.setArrivedAtStartAt(LocalDateTime.now());
        participant.setStateUpdatedAt(LocalDateTime.now());
        participantRepository.save(participant);

        if (ride.getStatus() == Status.CREATED
                || ride.getStatus() == Status.SCHEDULED
                || ride.getStatus() == Status.PARTIAL_STARTED) {
            ride.setStatus(Status.READY_TO_START);
            rideRepository.save(ride);
        }

        return getRideSession(rideUuid, actorUserUuid);
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
        return getRideSession(rideUuid, actorUserUuid);
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

        return getRideSession(rideUuid, actorUserUuid);
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

        return getRideSession(rideUuid, actorUserUuid);
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
