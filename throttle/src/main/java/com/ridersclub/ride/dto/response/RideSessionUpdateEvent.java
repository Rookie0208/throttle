package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;

import lombok.Builder;
import lombok.Getter;

@Builder
@Getter
public class RideSessionUpdateEvent {
    private String rideUuid;
    private String eventType;
    private LocalDateTime occurredAt;
}
