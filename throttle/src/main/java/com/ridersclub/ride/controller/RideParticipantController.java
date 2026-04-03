package com.ridersclub.ride.controller;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.ridersclub.common.Utils.ApiConstants;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.ride.dto.request.AssignRoleRequest;
import com.ridersclub.ride.dto.request.InviteRideMemberRequest;
import com.ridersclub.ride.service.RideParticipantService;

import jakarta.validation.Valid;

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

    @GetMapping("/{rideId}/invite-candidates")
    public ApiResponse<?> getInviteCandidates(
            @PathVariable String rideId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                participantService.getInviteCandidates(rideId, currentUserUuid),
                "Invite candidates fetched");
    }

    @PutMapping("/{rideId}/{userId}/role")
    public ApiResponse<?> updateRole(
            @PathVariable String rideId,
            @PathVariable String userId,
            @RequestBody AssignRoleRequest request,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        participantService.updateRole(rideId, userId, request.getRole(), currentUserUuid);
        return ApiResponse.success(null, "Role updated successfully");
    }

    @PostMapping(ApiConstants.RideParticipant.INVITE)
    public ApiResponse<?> inviteMember(
            @PathVariable String rideId,
            @Valid @RequestBody InviteRideMemberRequest request,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                participantService.inviteMember(rideId, request.getInviteeUuid(), currentUserUuid),
                "Ride invitation sent successfully");
    }

    @GetMapping(ApiConstants.RideParticipant.INVITATION_DETAILS)
    public ApiResponse<?> getInvitationDetails(
            @PathVariable Long invitationId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                participantService.getInvitationDetails(invitationId, currentUserUuid),
                "Invitation details fetched");
    }

    @PostMapping(ApiConstants.RideParticipant.INVITATION_ACCEPT)
    public ApiResponse<?> acceptInvitation(
            @PathVariable Long invitationId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        participantService.acceptInvitation(invitationId, currentUserUuid);
        return ApiResponse.success(null, "Ride invitation accepted");
    }

    @PostMapping(ApiConstants.RideParticipant.INVITATION_REJECT)
    public ApiResponse<?> rejectInvitation(
            @PathVariable Long invitationId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        participantService.rejectInvitation(invitationId, currentUserUuid);
        return ApiResponse.success(null, "Ride invitation rejected");
    }
}
