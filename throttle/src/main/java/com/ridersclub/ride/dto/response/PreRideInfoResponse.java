package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import com.ridersclub.common.enums.RouteType;
import com.ridersclub.common.enums.RideType;
import com.ridersclub.common.enums.Visibility;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PreRideInfoResponse {
    private String title;
    private String description;
    private RideType rideType;
    private RouteType routeType;
    private Integer maxRiders;
    private Visibility visibility;
    private LocalDateTime startTime;
    private Map<String, Object> startLocation;
    private Map<String, Object> endLocation;
    private String meetingPoint;
    private Map<String, Object> meetingPointLocation;
    private String fuelStops;
    private List<String> checkpointList;
    private List<Map<String, Object>> checkpointLocations;
    private List<String> ruleList;
    private String notes;
    private LocalDateTime updatedAt;
}
