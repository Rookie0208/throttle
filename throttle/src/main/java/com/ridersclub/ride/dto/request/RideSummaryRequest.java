package com.ridersclub.ride.dto.request;

import lombok.Data;

@Data
public class RideSummaryRequest {
private double distanceKm;
    private long durationMinutes;
    private double avgSpeed;
}
