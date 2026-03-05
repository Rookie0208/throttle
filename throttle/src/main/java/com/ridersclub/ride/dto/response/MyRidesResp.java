package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;

import com.ridersclub.common.enums.RideType;
import com.ridersclub.common.enums.RouteType;
import com.ridersclub.common.enums.Status;
import com.ridersclub.common.enums.Visibility;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MyRidesResp {

    private String uuid;
    private String title;
    private String description;

    private RideType rideType;
    private RouteType routeType;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    private String startLocation;
    private String endLocation;

    private Double startLat;
    private Double startLng;
    private Double endLat;
    private Double endLng;

    private Integer maxRiders;

    private String createdByUuid; // only user UUID, not full User object
    private String captainUuid;   // only user UUID if assigned

    private Visibility visibility;
    private Status status;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

}