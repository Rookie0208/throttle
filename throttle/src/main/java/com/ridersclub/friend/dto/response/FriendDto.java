package com.ridersclub.friend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FriendDto {
    private String uuid;
    private String riderId;
    private String firstName;
    private String lastName;
    private String username;
    private String profileImage;
    private String city;
    private boolean requestSent;
    private int mutualFriends;
}
