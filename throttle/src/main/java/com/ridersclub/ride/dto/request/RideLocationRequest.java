package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RideLocationRequest {
    @NotBlank
    private String name;

    @NotNull
    private Double latitude;

    @NotNull
    private Double longitude;
}
