package com.ridersclub.ride.dto.response;

import java.time.LocalDateTime;
import java.util.List;

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
public class ClubResponse {
    private String uuid;
    private String name;
    private String title;
    private String description;
    private String bannerUrl;
    private int memberCount;
    private int subgroupCount;
    private String myRole;
    private boolean member;
    private String createdByName;
    private LocalDateTime createdAt;
    private List<ClubSubgroupResponse> subgroups;
}
