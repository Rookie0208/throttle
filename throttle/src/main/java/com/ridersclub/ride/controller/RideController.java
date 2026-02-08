package com.ridersclub.ride.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;

import com.ridersclub.common.dto.ApiErrors;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.dto.response.RideResponse;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.service.RideService;
import com.ridersclub.user.entity.User;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Controller
@RequestMapping("/api/v1/rides")
@RequiredArgsConstructor
public class RideController {
    private final RideService rideService;

    @PostMapping("/create")
    public ResponseEntity<ApiResponse<RideResponse>> createRide(@Valid @RequestBody CreateRideRequest request,
            User currentUser) throws AccessDeniedException {
                RideResponse response = null;
        try {
            Ride ride = rideService.createRide(request, currentUser);
            response = new RideResponse(ride.getRideUid());
            System.out.println("Ride created with UID: " + ride.getRideUid());
        } catch (Exception e) {
            System.out.println(e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.failure(new ApiErrors("RIDE_CREATION_FAILED", e.getMessage(), "/api/v1/rides/create"), "You are not allowed to create rides"));
        }
        return ResponseEntity.ok(ApiResponse.success(response, "Ride created successfully"));
    }
}
