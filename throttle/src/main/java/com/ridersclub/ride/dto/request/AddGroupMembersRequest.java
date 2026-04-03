package com.ridersclub.ride.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

@Data
public class AddGroupMembersRequest {

    @NotEmpty(message = "memberUuids is required")
    private List<String> memberUuids;
}
