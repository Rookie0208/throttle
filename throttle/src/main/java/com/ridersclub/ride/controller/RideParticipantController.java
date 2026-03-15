package com.ridersclub.ride.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ridersclub.common.Utils.ApiConstants;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.ride.service.RideParticipantService;

@RestController
@RequestMapping(ApiConstants.RideParticipant.BASE)
public class RideParticipantController {

    private final RideParticipantService participantService;

    public RideParticipantController(RideParticipantService participantService) {
        this.participantService = participantService;
    }

    @PostMapping(ApiConstants.RideParticipant.JOIN)
    public ApiResponse<?> joinRide(@PathVariable String rideId) {
        // participantService.joinRide(rideId);
        return ApiResponse.success(null, "Joined ride successfully");
    }

    @PostMapping(ApiConstants.RideParticipant.LEAVE)
    public ApiResponse<?> leaveRide(@PathVariable String rideId) {
        // participantService.leaveRide(rideId);
        return ApiResponse.success(null, "Left ride");
    }

    @GetMapping(ApiConstants.RideParticipant.LIST)
    public ApiResponse<?> getParticipants(@PathVariable String rideId) {
        return ApiResponse.success(participantService.getRideParticipants(rideId),"Participants fetched");
    }
}
