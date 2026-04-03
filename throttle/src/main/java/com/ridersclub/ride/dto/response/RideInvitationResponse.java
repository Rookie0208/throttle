package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;

import com.ridersclub.common.enums.RideInvitationStatus;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RideInvitationResponse {
    private Long id;
    private String rideUuid;
    private String rideTitle;
    private String rideDescription;
    private LocalDateTime rideStartTime;
    private String meetingPoint;
    private String inviterUuid;
    private String inviterName;
    private String inviteeUuid;
    private String inviteeName;
    private RideInvitationStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime respondedAt;
}
