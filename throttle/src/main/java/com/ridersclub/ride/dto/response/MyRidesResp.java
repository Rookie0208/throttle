package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.ridersclub.common.enums.RideType;
import com.ridersclub.common.enums.RouteType;
import com.ridersclub.common.enums.Status;
import com.ridersclub.common.enums.Visibility;
import com.ridersclub.ride.entity.RideLocation;

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
    private String groupUuid;
    private String title;
    private String description;

    private RideType rideType;
    private RouteType routeType;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    // route locations
    private List<RideLocationResp> locations;

    private Integer maxRiders;

    private String createdByUuid;
    private String createdByName;
    private String captainUuid;
    private String myRole;
    private String membershipStatus;
    @JsonProperty("isMember")
    private boolean isMember;

    private Visibility visibility;
    private Status status;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
