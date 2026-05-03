package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CustomRideCheckpointRequest {
    @NotBlank
    private String title;
    private Double latitude;
    private Double longitude;
}
