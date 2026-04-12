package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RideSosRequest {
    @NotBlank(message = "SOS message is required")
    @Size(max = 100, message = "SOS message must be 100 characters or fewer")
    private String message;
}
