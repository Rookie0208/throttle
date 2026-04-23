package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClubSubgroupResponse {
    private String uuid;
    private String name;
    private int memberCount;
    private boolean member;
    private LocalDateTime createdAt;
}
