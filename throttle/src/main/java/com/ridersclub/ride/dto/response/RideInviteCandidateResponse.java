package com.ridersclub.ride.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class RideInviteCandidateResponse {
    private String userUuid;
    private String riderId;
    private String firstName;
    private String lastName;
    private String profileImage;
    private String email;
    private boolean clubFriend;
    private boolean invitationPending;
}
