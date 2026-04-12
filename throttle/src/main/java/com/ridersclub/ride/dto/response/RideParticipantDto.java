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
    private String profileImage;

    private String role; // CAPTAIN / MEMBER
    private String rsvpStatus; // ACCEPTED / PENDING
    private String participantState;
    private Double lastLatitude;
    private Double lastLongitude;
    private LocalDateTime lastLocationUpdatedAt;

    private LocalDateTime joinedAt;
}
