package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;
import java.util.List;

import com.ridersclub.common.enums.RideType;
import com.ridersclub.common.enums.RouteType;
import com.ridersclub.common.enums.Status;
import com.ridersclub.common.enums.Visibility;
import com.ridersclub.ride.entity.RideLocation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

import com.ridersclub.common.enums.Visibility;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
@Getter
@Setter
public class SubGroupResponse {

    private String uuid;
    private String name;

    private String rideUuid;
    private String parentGroupUuid;

    private Visibility visibility;

    private boolean membersCanSendMessages;

    private boolean membersCanAddMembers;

    private String createdByUuid;

    private LocalDateTime createdAt;
}