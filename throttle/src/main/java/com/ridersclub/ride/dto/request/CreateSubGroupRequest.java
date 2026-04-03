package com.ridersclub.ride.dto.request;

import java.util.List;

import com.ridersclub.common.enums.Visibility;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateSubGroupRequest {
    @NotBlank(message = "name is required")
    private String name;

    @NotBlank(message = "rideUuid is required")
    private String rideUuid;

    @NotNull(message = "visibility is required")
    private Visibility visibility;

    private boolean membersCanSendMessages;

    private boolean membersCanAddMembers;

    private boolean adminsApproveMembers = true;

    private List<String> memberUuids;
}
