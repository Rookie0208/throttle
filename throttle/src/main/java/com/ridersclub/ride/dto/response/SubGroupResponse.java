package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.ridersclub.common.enums.Visibility;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SubGroupResponse {

    private String uuid;
    private String name;
    private String title;
    private String description;
    private String rideUuid;
    private String parentGroupUuid;
    private Visibility visibility;
    private boolean membersCanSendMessages;
    private boolean membersCanAddMembers;
    private boolean adminsApproveMembers;
    private String createdByUuid;
    private String createdByName;
    private String myRole;
    @JsonProperty("isMember")
    private boolean isMember;
    private boolean joinRequestPending;
    private boolean canJoinDirectly;
    private boolean canRequestToJoin;
    private int memberCount;
    private Map<String, Object> preRideInfo;
    private LocalDateTime createdAt;
}
