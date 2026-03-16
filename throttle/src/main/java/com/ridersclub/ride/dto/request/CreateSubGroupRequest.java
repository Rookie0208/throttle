package com.ridersclub.ride.dto.request;

import java.util.List;

import com.ridersclub.common.enums.Visibility;

import lombok.Data;

@Data
public class CreateSubGroupRequest {
    private String name;

    private String rideUuid;

    private Visibility visibility;

    private boolean membersCanSendMessages;

    private boolean membersCanAddMembers;

    private List<String> memberUuids;
}
