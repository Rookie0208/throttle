package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class RideSosResolutionRequest {
    @NotBlank(message = "Resolution is required")
    @Pattern(
            regexp = "ACCEPTED|REJECTED",
            message = "Resolution must be ACCEPTED or REJECTED")
    private String resolution;
}
