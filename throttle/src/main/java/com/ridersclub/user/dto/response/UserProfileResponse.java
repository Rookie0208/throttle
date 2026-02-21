package com.ridersclub.user.dto.response;

import com.ridersclub.user.entity.User;

import lombok.Data;

@Data
public class UserProfileResponse {
private String id;
    private String firstName;
    private String lastName;
    private String email;
    private String bio;
    private String profileImage;

    public UserProfileResponse(User user) {
        this.id = user.getUuid().toString();
        this.firstName = user.getFirstName();
        this.lastName = user.getLastName();
        this.email = user.getEmail();
        this.bio = user.getBio();
        this.profileImage = user.getProfileImage();
    }
}
