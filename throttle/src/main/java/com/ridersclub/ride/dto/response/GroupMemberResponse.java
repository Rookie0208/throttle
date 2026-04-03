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
public class GroupMemberResponse {
    private String userUuid;
    private String firstName;
    private String lastName;
    private String profileImage;
    private String role;
    private LocalDateTime joinedAt;
}
