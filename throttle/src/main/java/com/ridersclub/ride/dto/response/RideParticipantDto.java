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
    private String firstName;
    private String lastName;
    private String profileImage;

    private String role; // CAPTAIN / MEMBER
    private String rsvpStatus; // ACCEPTED / PENDING

    private LocalDateTime joinedAt;
}
