package com.ridersclub.user.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.user.dto.request.UpdateProfileRequest;
import com.ridersclub.user.dto.response.UserProfileResponse;
import com.ridersclub.user.service.UserService;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getMyProfile(
            @AuthenticationPrincipal Authentication user) {
        UserProfileResponse profile = userService.getProfileByUUID((String) user.getPrincipal());
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(profile, "Profile Fetched Successfully"));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            @AuthenticationPrincipal Authentication user,
            @RequestBody UpdateProfileRequest request) {
        UserProfileResponse updatedProfile = userService.updateProfile((String) user.getPrincipal(), request);
        return ResponseEntity.status(HttpStatus.OK).body(ApiResponse.success(updatedProfile, "Profile updated"));
    }
}
