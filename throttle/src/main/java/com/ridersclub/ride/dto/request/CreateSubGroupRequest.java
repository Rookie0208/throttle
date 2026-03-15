package com.ridersclub.ride.dto.request;

import java.util.List;

import lombok.Data;

@Data
public class CreateSubGroupRequest {
    private String name;

    private String rideUuid;

    private List<String> memberUuids;
}
