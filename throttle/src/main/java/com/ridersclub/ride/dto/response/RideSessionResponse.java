package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;
import java.util.List;

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
    private boolean currentUserCaptain;
    private String currentUserRole;
    private String currentUserState;
    private String meetingPoint;
    private String fuelStops;
    private Integer currentCheckpointIndex;
    private String latestBroadcastMessage;
    private LocalDateTime latestBroadcastAt;
    private Integer participantsCount;
    private Integer enRouteCount;
    private Integer atStartCount;
    private Integer inRideCount;
    private List<RideSessionCheckpointResponse> checkpoints;
    private List<RideParticipantDto> participants;
}
