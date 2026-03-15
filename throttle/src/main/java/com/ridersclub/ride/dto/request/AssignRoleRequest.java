package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;

import lombok.Data;

@Data
public class AssignRoleRequest {

    @NotBlank(message = "User ID is required")
    private String userId;

    @NotBlank(message = "Role is required")
    private String role;

}