package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;

import com.ridersclub.common.enums.GroupJoinRequestStatus;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class GroupJoinRequestResponse {
    private Long requestId;
    private String userUuid;
    private String firstName;
    private String lastName;
    private String profileImage;
    private String riderId;
    private String groupUuid;
    private String groupName;
    private GroupJoinRequestStatus status;
    private LocalDateTime requestedAt;
}
