package com.ridersclub.ride.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;

import com.ridersclub.common.dto.ApiErrors;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.dto.request.RideSummaryRequest;
import com.ridersclub.ride.dto.response.RideResponse;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.service.RideService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Controller
@RequestMapping("/api/v1/rides")
@RequiredArgsConstructor
public class RideController {
    private static final Logger logger = LoggerFactory.getLogger(RideController.class);

    @Autowired
    private RideService rideService;

    @PostMapping("/create")
    public ResponseEntity<ApiResponse<RideResponse>> createRide(@RequestBody CreateRideRequest request,
            Authentication authentication) throws AccessDeniedException {
        RideResponse response = null;
        String userId = (String) authentication.getPrincipal();
        System.out.println("Creating ride for user: " + userId);
        try {
            logger.debug("current user : {}", userId);
            Ride ride = rideService.createRide(request, userId);
            response = new RideResponse(ride.getUuid());
            logger.info("Ride created with rideID: {}", ride.getUuid());
        } catch (Exception e) {
            logger.error("error creating ride", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.failure(
                            new ApiErrors("RIDE_CREATION_FAILED", e.getMessage(), "/api/v1/rides/create"),
                            "You are not allowed to create rides"));
        }
        return ResponseEntity.ok(ApiResponse.success(response, "Ride created successfully"));
    }

    @GetMapping("/my")
    public ApiResponse<?> my(Authentication authentication) {
        String userId = (String) authentication.getPrincipal();
        System.out.println("getting my rides for user : " + userId);
        return ApiResponse.success(rideService.myRides(userId), "My rides");
    }

    @PostMapping("/{id}/join")
    public ApiResponse<?> join(@PathVariable String id,
            @AuthenticationPrincipal UserDetails user) {

        rideService.join(id, user.getUsername());
        return ApiResponse.success(null, "Joined ride");
    }

    @GetMapping("/{id}/participants")
    public ApiResponse<?> participants(@PathVariable String id) {
        return ApiResponse.success(rideService.participants(id), "Participants");
    }

    @PostMapping("/{id}/complete")
    public ApiResponse<?> complete(@PathVariable String id,
            Authentication authentication) {

        String userUuid = authentication.getName();

        rideService.complete(id, userUuid);
        return ApiResponse.success(null, "Ride completed successfully");
    }

    @PostMapping("/{id}/stats")
    public ApiResponse<?> stats(@PathVariable String id,
            @RequestBody RideSummaryRequest req,
            @AuthenticationPrincipal UserDetails user) {

        rideService.addStats(id, user.getUsername(), req);
        return ApiResponse.success(null, "Stats saved");
    }
}