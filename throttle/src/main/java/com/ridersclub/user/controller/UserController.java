package com.ridersclub.user.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.extern.slf4j.Slf4j;

import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.common.Utils.ApiConstants;
import com.ridersclub.user.dto.request.UpdateProfileRequest;
import com.ridersclub.user.dto.response.UserProfileResponse;
import com.ridersclub.user.service.UserService;

@Slf4j
@RestController
@RequestMapping(ApiConstants.Users.BASE)
public class UserController {

    UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping(ApiConstants.Users.ME)
    public ResponseEntity<ApiResponse<UserProfileResponse>> getMyProfile(Authentication user) {
        if (user == null || user.getPrincipal() == null) {
            log.error("getMyProfile called with null authentication");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.failure(null, "Authentication required"));
        }
        UserProfileResponse profile = userService.getProfileByUUID((String) user.getPrincipal());
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(profile, "Profile Fetched Successfully"));
    }

    @GetMapping(ApiConstants.Users.DETAILS)
    public ResponseEntity<ApiResponse<UserProfileResponse>> getProfileByUserId(
            @PathVariable("userId") String userId) {
        UserProfileResponse profile = userService.getProfileByUUID(userId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(profile, "Profile Fetched Successfully"));
    }

    @PutMapping(ApiConstants.Users.ME)
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            Authentication user,
            @Valid @RequestBody UpdateProfileRequest request) {
        String uuid = (String) user.getPrincipal();
        UserProfileResponse updatedProfile = userService.updateProfile(uuid, request);
        return ResponseEntity.status(HttpStatus.OK).body(ApiResponse.success(updatedProfile, "Profile updated"));
    }
}
