package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Builder
@Getter
@Setter
public class RideSessionResponse {
    private String rideUuid;
    private String title;
    private String rideStatus;
    private LocalDateTime scheduledStartTime;
    private LocalDateTime rideStartedAt;
    private LocalDateTime rideCompletedAt;
    private String captainUuid;
    private String captainName;
    private String currentUserUuid;
    private boolean currentUserCaptain;
    private String currentUserRole;
    private String currentUserState;
    private LocalDateTime currentUserRideStartedAt;
    private LocalDateTime currentUserArrivedAtStartAt;
    private LocalDateTime currentUserReturnStartTime;
    private LocalDateTime currentUserReturnEndTime;
    private Long currentUserTimeToMeetingSeconds;
    private Long currentUserGroupRideDurationSeconds;
    private Long currentUserReturnRideDurationSeconds;
    private Long currentUserTotalRideDurationSeconds;
    private String meetingPoint;
    private Map<String, Object> meetingPointLocation;
    private String fuelStops;
    private Integer currentCheckpointIndex;
    private String latestBroadcastMessage;
    private LocalDateTime latestBroadcastAt;
    private String activeSosMessage;
    private LocalDateTime activeSosAt;
    private String activeSosRaisedByName;
    private String activeSosRaisedByUuid;
    private String activeSosResolution;
    private LocalDateTime activeSosResolvedAt;
    private String activeSosResolvedByName;
    private String activeSosResolvedByUuid;
    private Integer participantsCount;
    private Integer enRouteCount;
    private Integer atStartCount;
    private Integer inRideCount;
    private Integer returnRideStartedCount;
    private Integer returnRideCompletedCount;
    private List<RideSessionCheckpointResponse> checkpoints;
    private List<RideParticipantDto> participants;
}
