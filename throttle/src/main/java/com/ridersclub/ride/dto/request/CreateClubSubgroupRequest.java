package com.ridersclub.ride.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateClubSubgroupRequest {

    @NotBlank(message = "Subgroup name is required")
    @Size(max = 120, message = "Subgroup name must be 120 characters or less")
    private String name;

    private List<String> memberUuids;
}
