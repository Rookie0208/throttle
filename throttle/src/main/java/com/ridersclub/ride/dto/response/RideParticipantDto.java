package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Builder
@Getter
@Setter
public class RideParticipantDto {
    private String userUuid;
    private String riderId;
    private String firstName;
    private String lastName;
    private String username;
    private String profileImage;

    private String role; // CAPTAIN / MEMBER
    private String rsvpStatus; // ACCEPTED / PENDING
    private String participantState;
    private Double lastLatitude;
    private Double lastLongitude;
    private LocalDateTime lastLocationUpdatedAt;
    private LocalDateTime joinedAt;
    private LocalDateTime rideStartedAt;
    private LocalDateTime arrivedAtStartAt;
    private LocalDateTime returnStartTime;
    private LocalDateTime returnEndTime;
    private Long rideToMeetingDurationSeconds;
    private Long groupRideDurationSeconds;
    private Long returnRideDurationSeconds;
    private Long totalRideDurationSeconds;
}
