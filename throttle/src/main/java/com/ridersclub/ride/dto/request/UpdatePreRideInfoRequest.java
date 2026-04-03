package com.ridersclub.ride.dto.request;

import java.util.List;

import lombok.Data;

@Data
public class UpdatePreRideInfoRequest {
    private String meetingPoint;
    private String fuelStops;
    private List<String> checkpointList;
    private List<String> ruleList;
    private String notes;
}
