package com.ridersclub.ride.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RideStats {
private String id;
    private String rideId;
    private String userId;
    private double distanceKm;
    private long durationMinutes;
    private double avgSpeed;
}
