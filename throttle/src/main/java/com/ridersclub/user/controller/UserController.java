package com.ridersclub.user.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.extern.slf4j.Slf4j;

import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.user.dto.request.UpdateProfileRequest;
import com.ridersclub.user.dto.response.UserProfileResponse;
import com.ridersclub.user.service.UserService;

@Slf4j
@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getMyProfile(
            Authentication user) {
        log.info("Received request for /api/v1/users/me");
        if (user == null || user.getPrincipal() == null) {
            log.error("Authentication object is null or has no principal!");
        } else {
            log.info("Fetching profile for user UUID: {}", user.getPrincipal());
        }

        UserProfileResponse profile = userService.getProfileByUUID((String) user.getPrincipal());
        log.info("Returning profile data for: {} {}", profile.getFirstName(), profile.getLastName());

        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(profile, "Profile Fetched Successfully"));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            Authentication user,
            @Valid @RequestBody UpdateProfileRequest request) {
        String uuid = (String) user.getPrincipal();
        UserProfileResponse updatedProfile = userService.updateProfile(uuid, request);
        return ResponseEntity.status(HttpStatus.OK).body(ApiResponse.success(updatedProfile, "Profile updated"));
    }
}
