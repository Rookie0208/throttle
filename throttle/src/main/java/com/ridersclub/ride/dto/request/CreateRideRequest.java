package com.ridersclub.ride.dto.request;

import java.time.OffsetDateTime;
import java.util.List;

import com.ridersclub.common.enums.RouteType;
import com.ridersclub.common.enums.Visibility;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateRideRequest {
    @NotBlank
    private String title;

    @Size(max = 1000)
    private String description;

    @NotNull
    private RideLocationRequest startLocation;

    @NotNull
    private RideLocationRequest endLocation;

    @NotNull
    private RouteType routeType;

    @NotNull
    @Future
    private OffsetDateTime startTime;

    @NotNull
    @Min(1)
    private Integer maxRiders;

    @NotNull
    private Visibility visibility;

    @NotEmpty
    private List<@NotBlank String> rules;
}
