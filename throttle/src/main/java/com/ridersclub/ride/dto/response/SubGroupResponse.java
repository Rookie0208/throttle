package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;

import com.ridersclub.common.enums.Visibility;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SubGroupResponse {

    private String uuid;
    private String name;
    private String rideUuid;
    private String parentGroupUuid;
    private Visibility visibility;
    private boolean membersCanSendMessages;
    private boolean membersCanAddMembers;
    private String createdByUuid;
    private String createdByName;
    private String myRole;
    private int memberCount;
    private LocalDateTime createdAt;
}
