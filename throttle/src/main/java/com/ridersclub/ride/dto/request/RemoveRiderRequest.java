package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;

import lombok.Data;

@Data
public class RemoveRiderRequest {

    @NotBlank(message = "User ID is required")
    private String userUuId;

}