package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;
import java.util.List;

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
    private String meetingPoint;
    private String fuelStops;
    private List<String> checkpointList;
    private List<String> ruleList;
    private String notes;
    private LocalDateTime updatedAt;
}
