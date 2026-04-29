package com.ridersclub.ride.dto.request;

import java.util.List;
import java.util.Map;

import lombok.Data;

@Data
public class UpdatePreRideInfoRequest {
    private Map<String, Object> startLocation;
    private Map<String, Object> endLocation;
    private String meetingPoint;
    private Map<String, Object> meetingPointLocation;
    private String fuelStops;
    private List<String> checkpointList;
    private List<Map<String, Object>> checkpointLocations;
    private List<String> ruleList;
    private String notes;
}
