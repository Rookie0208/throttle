package com.ridersclub.ride.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Builder
@Getter
@Setter
public class RideSessionCheckpointResponse {
    private Integer sequence;
    private String title;
    private Double latitude;
    private Double longitude;
    private String checkpointStatus;
}
