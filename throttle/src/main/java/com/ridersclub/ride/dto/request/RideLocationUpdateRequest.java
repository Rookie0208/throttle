package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RideLocationUpdateRequest {
    @NotNull
    private Double latitude;

    @NotNull
    private Double longitude;
}
