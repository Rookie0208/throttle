package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Builder
@Getter
@Setter
public class RideBroadcastResponse {
    private String message;
    private LocalDateTime createdAt;
}
