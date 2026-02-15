package com.ridersclub.ride.entity;

import java.time.LocalDateTime;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RideParticipant {
private Long id;
    private String rideId;
    private String userId;
    private LocalDateTime joinedAt;
}
