package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateClubRequest {

    @NotBlank(message = "Club name is required")
    @Size(max = 120, message = "Club name must be 120 characters or less")
    private String name;

    @Size(max = 160, message = "Club title must be 160 characters or less")
    private String title;

    @Size(max = 2000, message = "Club description must be 2000 characters or less")
    private String description;
}
