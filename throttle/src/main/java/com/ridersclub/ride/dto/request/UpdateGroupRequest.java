package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateGroupRequest {
    @NotBlank(message = "name is required")
    private String name;
}
