package com.ridersclub.ride.dto.response;

import com.ridersclub.common.enums.LocationType;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class RideLocationResp {

    private String name;
    private Double latitude;
    private Double longitude;

    private LocationType locationType;

    private Integer sequence;
}