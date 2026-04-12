package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class InviteRideMemberRequest {

    @NotBlank(message = "inviteeUuid is required")
    private String inviteeUuid;
}
