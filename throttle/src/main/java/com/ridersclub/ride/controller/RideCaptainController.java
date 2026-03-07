package com.ridersclub.ride.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.ride.dto.request.AssignRoleRequest;
import com.ridersclub.ride.dto.request.RemoveRiderRequest;
import com.ridersclub.ride.service.RideCaptainService;
import com.ridersclub.common.Utils.ApiConstants;

@RestController
@RequestMapping(ApiConstants.Rides.BASE)
public class RideCaptainController {

    private final RideCaptainService captainService;

    public RideCaptainController(RideCaptainService captainService) {
        this.captainService = captainService;
    }

    @PostMapping(ApiConstants.RideCaptain.ASSIGN_ROLE)
    public ApiResponse<?> assignRole(
            @PathVariable String rideId,
            @RequestBody AssignRoleRequest request) {

        // captainService.assignRole(rideId, request);
        return ApiResponse.success(null, "Role assigned");
    }

    @PostMapping(ApiConstants.RideCaptain.REMOVE_RIDER)
    public ApiResponse<?> removeRider(
            @PathVariable String rideId,
            @RequestBody RemoveRiderRequest request) {

        // captainService.removeRider(rideId, request);
        return ApiResponse.success(null, "Rider removed");
    }
}