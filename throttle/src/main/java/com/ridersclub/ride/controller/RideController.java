package com.ridersclub.ride.controller;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PutMapping;

import com.ridersclub.common.dto.ApiErrors;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.ride.dto.request.AddGroupMembersRequest;
import com.ridersclub.ride.dto.request.AssignRoleRequest;
import com.ridersclub.ride.dto.request.CustomRideCheckpointRequest;
import com.ridersclub.ride.dto.request.CreateRideRequest;
import com.ridersclub.ride.dto.request.RideAnnouncementRequest;
import com.ridersclub.ride.dto.request.CreateSubGroupRequest;
import com.ridersclub.ride.dto.request.RideLocationUpdateRequest;
import com.ridersclub.ride.dto.request.RideSosRequest;
import com.ridersclub.ride.dto.request.RideSosResolutionRequest;
import com.ridersclub.ride.dto.request.RideSummaryRequest;
import com.ridersclub.ride.dto.request.UpdateGroupRequest;
import com.ridersclub.ride.dto.request.UpdatePreRideInfoRequest;
import com.ridersclub.ride.dto.response.GroupJoinRequestResponse;
import com.ridersclub.ride.dto.response.PreRideInfoResponse;
import com.ridersclub.ride.dto.response.RideResponse;
import com.ridersclub.ride.dto.response.RideSessionResponse;
import com.ridersclub.ride.dto.response.SubGroupResponse;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.ride.repository.RideGroupRepository;
import com.ridersclub.ride.service.RideParticipantService;
import com.ridersclub.ride.service.RideSessionService;
import com.ridersclub.ride.service.RideService;
import com.ridersclub.user.entity.User;
import com.ridersclub.common.Utils.ApiConstants;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import jakarta.validation.Valid;

@Slf4j
@RestController
@RequestMapping(ApiConstants.Rides.BASE)
@RequiredArgsConstructor
public class RideController {

    @Autowired
    private RideService rideService;

    @Autowired
    private RideGroupRepository rideGroupRepository;
    @Autowired
    private RideParticipantService rideParticipantService;
    @Autowired
    private RideSessionService rideSessionService;

    @PostMapping(ApiConstants.Rides.CREATE)
    public ResponseEntity<ApiResponse<RideResponse>> createRide(@Valid @RequestBody CreateRideRequest request,
            Authentication authentication) throws AccessDeniedException {
        RideResponse response = null;
        String userId = (String) authentication.getPrincipal();
        try {
            log.debug("Creating ride for user: {}", userId);
            Ride ride = rideService.createRide(request, userId);
            response = new RideResponse(ride.getUuid());
            log.info("Ride created with rideID: {}", ride.getUuid());
        } catch (IllegalArgumentException e) {
            log.warn("Invalid ride creation request: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.failure(
                            new ApiErrors("RIDE_VALIDATION_FAILED", e.getMessage(), "/api/v1/rides/create"),
                            e.getMessage()));
        } catch (Exception e) {
            log.error("Error creating ride", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.failure(
                            new ApiErrors("RIDE_CREATION_FAILED", e.getMessage(), "/api/v1/rides/create"),
                            "You are not allowed to create rides"));
        }
        return ResponseEntity.ok(ApiResponse.success(response, "Ride created successfully"));
    }

    @GetMapping(ApiConstants.Rides.MY_RIDES)
    public ApiResponse<?> my(Authentication authentication) {
        String userId = (String) authentication.getPrincipal();
        return ApiResponse.success(rideService.myRides(userId), "My rides");
    }

    @GetMapping("/public")
    public ApiResponse<?> publicRides(Authentication authentication) {
        String userId = (String) authentication.getPrincipal();
        return ApiResponse.success(rideService.getPublicRides(userId), "Public rides fetched");
    }

    /*
    Need an endpont to fetch public rides.
    GET /rides/public
    {
  "success": true,
  "message": "Public rides fetched",
  "data": [
    {
      "uuid": "123",
      "title": "Sunday Ride",
      "description": "Ride to hills",
      "rideType": "ADVENTURE",
      "routeType": "HIGHWAY",
      "startTime": "2026-03-25T07:00:00",
      "maxRiders": 10
    }
  ]
}
    */

    @PostMapping(ApiConstants.Rides.JOIN)
    public ApiResponse<?> join(@PathVariable String id,
            Authentication authentication) {

        String userUuid = authentication.getPrincipal().toString();
        rideService.join(id, userUuid);
        return ApiResponse.success(null, "Joined ride");
    }

    // @GetMapping(ApiConstants.Rides.LIST)
    // public ApiResponse<?> participants(@PathVariable String id) {
    // return ApiResponse.success(rideService.participants(id), "Participants");
    // }

    @PostMapping(ApiConstants.Rides.COMPLETE)
    public ApiResponse<?> complete(@PathVariable String id,
            Authentication authentication) {

        String userUuid = authentication.getName();

        rideService.complete(id, userUuid);
        return ApiResponse.success(null, "Ride completed successfully");
    }

    @PostMapping(ApiConstants.Rides.CANCEL)
    public ApiResponse<?> cancel(@PathVariable String id,
            Authentication authentication) {

        String userUuid = authentication.getName();

        rideService.cancel(id, userUuid);
        return ApiResponse.success(null, "Ride cancelled successfully");
    }

    @GetMapping("/{id}/session")
    public ApiResponse<RideSessionResponse> getRideSession(
            @PathVariable String id,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.getRideSession(id, userUuid),
                "Ride session fetched");
    }

    @PostMapping(ApiConstants.Rides.START)
    public ApiResponse<RideSessionResponse> startRide(
            @PathVariable String id,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.startRide(id, userUuid),
                "Ride started successfully");
    }

    @PostMapping(ApiConstants.Rides.DROP)
    public ApiResponse<RideSessionResponse> dropRide(
            @PathVariable String id,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.dropFromRide(id, userUuid),
                "Ride dropped successfully");
    }

    @PostMapping(ApiConstants.Rides.START_RETURN)
    public ApiResponse<RideSessionResponse> startReturnRide(
            @PathVariable String id,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.startReturnRide(id, userUuid),
                "Return ride started successfully");
    }

    @PostMapping(ApiConstants.Rides.END_RETURN)
    public ApiResponse<RideSessionResponse> endReturnRide(
            @PathVariable String id,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.endReturnRide(id, userUuid),
                "Return ride completed successfully");
    }

    @PostMapping("/{id}/partial-start")
    public ApiResponse<RideSessionResponse> partialStartRide(
            @PathVariable String id,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.partialStart(id, userUuid),
                "Partial start updated");
    }

    @PostMapping("/{id}/arrive-start")
    public ApiResponse<RideSessionResponse> arriveAtStart(
            @PathVariable String id,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.markArrivedAtStart(id, userUuid),
                "Arrival at start point updated");
    }

    @PostMapping("/{id}/location")
    public ApiResponse<RideSessionResponse> updateRideLocation(
            @PathVariable String id,
            @Valid @RequestBody RideLocationUpdateRequest request,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.updateLocation(id, userUuid, request),
                "Ride location updated");
    }

    @PostMapping("/{id}/checkpoints/advance")
    public ApiResponse<RideSessionResponse> advanceCheckpoint(
            @PathVariable String id,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.advanceCheckpoint(id, userUuid),
                "Checkpoint advanced");
    }

    @PostMapping("/{id}/checkpoints/custom")
    public ApiResponse<RideSessionResponse> addCustomCheckpoint(
            @PathVariable String id,
            @Valid @RequestBody CustomRideCheckpointRequest request,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.addCustomCheckpoint(id, userUuid, request),
                "Checkpoint added");
    }

    @PostMapping("/{id}/sos")
    public ApiResponse<RideSessionResponse> sendSos(
            @PathVariable String id,
            @Valid @RequestBody RideSosRequest request,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.sendSos(id, userUuid, request),
                "SOS sent");
    }

    @PostMapping("/{id}/sos/resolve")
    public ApiResponse<RideSessionResponse> resolveSos(
            @PathVariable String id,
            @Valid @RequestBody RideSosResolutionRequest request,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideSessionService.resolveSos(id, userUuid, request),
                "SOS resolved");
    }

    @PostMapping(ApiConstants.Rides.STATS)
    public ApiResponse<?> stats(@PathVariable String id,
            @RequestBody RideSummaryRequest req,
            @AuthenticationPrincipal UserDetails user) {

        rideService.addStats(id, user.getUsername(), req);
        return ApiResponse.success(null, "Stats saved");
    }

    @PostMapping("/{id}/announcement")
    public ApiResponse<?> publishAnnouncement(
            @PathVariable String id,
            @Valid @RequestBody RideAnnouncementRequest request,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        rideParticipantService.publishAnnouncement(id, request.getMessage(), userUuid);
        return ApiResponse.success(null, "Announcement sent successfully");
    }

    /**
     * Subgroup related APIs
     * final payload = {
     * "name": "Breakfast Crew",
     * "parentGroupUuid": groupId,
     * "memberUuids": selectedMembers
     * };
     * 
     */
    @PostMapping("/subgroup")
    public ResponseEntity<ApiResponse<SubGroupResponse>> createSubGroup(
            @Valid @RequestBody CreateSubGroupRequest request, Authentication authentication) {
        try {
            String userUuid = authentication.getPrincipal().toString();
            SubGroupResponse group = rideService.createSubGroup(request, userUuid);
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(group, "Subgroup created successfully"));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.failure(
                            new ApiErrors("SUBGROUP_CREATION_FAILED", e.getMessage(), "/api/v1/rides/subgroup"),
                            e.getMessage()));
        } catch (Exception e) {
            log.error("Error creating subgroup", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.failure(
                            new ApiErrors("SUBGROUP_CREATION_FAILED", e.getMessage(), "/api/v1/rides/subgroup"),
                            e.getMessage()));
        }
    }

    @GetMapping("/{groupUuid}/subgroups")
    public ApiResponse<?> getSubGroups(@PathVariable String groupUuid, Authentication authentication) {

        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(rideService.getSubGroups(groupUuid, userUuid), "Subgroups");
    }

    @GetMapping("/groups/{groupUuid}")
    public ApiResponse<?> getGroupDetails(@PathVariable String groupUuid, Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(rideService.getGroupDetails(groupUuid, userUuid), "Group details");
    }

    @GetMapping("/{rideUuid}/main-group")
    public ApiResponse<?> getMainGroupDetails(
            @PathVariable String rideUuid,
            Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideService.getMainGroupDetailsByRideUuid(rideUuid, userUuid),
                "Main group details");
    }

    @GetMapping("/groups/{groupUuid}/members")
    public ApiResponse<?> getGroupMembers(@PathVariable String groupUuid, Authentication authentication) {
        String userUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(rideService.getGroupMembers(groupUuid, userUuid), "Group members");
    }

    @PostMapping("/groups/{groupUuid}/members")
    public ApiResponse<?> addGroupMembers(
            @PathVariable String groupUuid,
            @Valid @RequestBody AddGroupMembersRequest request,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        rideService.addGroupMembers(groupUuid, request.getMemberUuids(), currentUserUuid);
        return ApiResponse.success(null, "Subgroup members added successfully");
    }

    @PutMapping("/groups/{groupUuid}/members/{userId}/role")
    public ApiResponse<?> updateGroupMemberRole(
            @PathVariable String groupUuid,
            @PathVariable String userId,
            @RequestBody AssignRoleRequest request,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        rideService.updateGroupMemberRole(groupUuid, userId, request.getRole(), currentUserUuid);
        return ApiResponse.success(null, "Subgroup role updated successfully");
    }

    @DeleteMapping("/groups/{groupUuid}/members/{userId}")
    public ApiResponse<?> removeGroupMember(
            @PathVariable String groupUuid,
            @PathVariable String userId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        rideService.removeGroupMember(groupUuid, userId, currentUserUuid);
        return ApiResponse.success(null, "Subgroup member removed successfully");
    }

    @GetMapping("/groups/{groupUuid}/join-requests")
    public ApiResponse<List<GroupJoinRequestResponse>> getJoinRequests(
            @PathVariable String groupUuid,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideService.getPendingJoinRequests(groupUuid, currentUserUuid),
                "Subgroup join requests fetched");
    }

    @GetMapping("/join-requests/{requestId}")
    public ApiResponse<GroupJoinRequestResponse> getJoinRequestDetails(
            @PathVariable Long requestId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideService.getJoinRequestDetails(requestId, currentUserUuid),
                "Join request details fetched");
    }

    @PostMapping("/groups/{groupUuid}/join")
    public ApiResponse<SubGroupResponse> joinGroup(
            @PathVariable String groupUuid,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideService.joinGroup(groupUuid, currentUserUuid),
                "Subgroup join request processed");
    }

    @PostMapping("/groups/{groupUuid}/join-requests/{requestId}/approve")
    public ApiResponse<?> approveJoinRequest(
            @PathVariable String groupUuid,
            @PathVariable Long requestId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        rideService.approveJoinRequest(groupUuid, requestId, currentUserUuid);
        return ApiResponse.success(null, "Join request approved");
    }

    @PostMapping("/join-requests/{requestId}/approve")
    public ApiResponse<?> approveJoinRequestFromNotification(
            @PathVariable Long requestId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        GroupJoinRequestResponse details = rideService.getJoinRequestDetails(requestId, currentUserUuid);
        rideService.approveJoinRequest(details.getGroupUuid(), requestId, currentUserUuid);
        return ApiResponse.success(null, "Join request approved");
    }

    @PostMapping("/groups/{groupUuid}/join-requests/{requestId}/reject")
    public ApiResponse<?> rejectJoinRequest(
            @PathVariable String groupUuid,
            @PathVariable Long requestId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        rideService.rejectJoinRequest(groupUuid, requestId, currentUserUuid);
        return ApiResponse.success(null, "Join request rejected");
    }

    @PostMapping("/join-requests/{requestId}/reject")
    public ApiResponse<?> rejectJoinRequestFromNotification(
            @PathVariable Long requestId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        GroupJoinRequestResponse details = rideService.getJoinRequestDetails(requestId, currentUserUuid);
        rideService.rejectJoinRequest(details.getGroupUuid(), requestId, currentUserUuid);
        return ApiResponse.success(null, "Join request rejected");
    }

    @DeleteMapping("/groups/{groupUuid}/leave")
    public ApiResponse<?> leaveGroup(
            @PathVariable String groupUuid,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        rideService.leaveGroup(groupUuid, currentUserUuid);
        return ApiResponse.success(null, "Exited subgroup successfully");
    }

    @PutMapping("/groups/{groupUuid}")
    public ApiResponse<SubGroupResponse> renameGroup(
            @PathVariable String groupUuid,
            @Valid @RequestBody UpdateGroupRequest request,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideService.renameGroup(groupUuid, request, currentUserUuid),
                "Group updated successfully");
    }

    @GetMapping("/groups/{groupUuid}/pre-ride-info")
    public ApiResponse<PreRideInfoResponse> getPreRideInfo(
            @PathVariable String groupUuid,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideService.getPreRideInfo(groupUuid, currentUserUuid),
                "Pre-ride info fetched");
    }

    @PutMapping("/groups/{groupUuid}/pre-ride-info")
    public ApiResponse<PreRideInfoResponse> updatePreRideInfo(
            @PathVariable String groupUuid,
            @RequestBody UpdatePreRideInfoRequest request,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                rideService.updatePreRideInfo(groupUuid, request, currentUserUuid),
                "Pre-ride info updated");
    }

    @DeleteMapping("/{id}/members/{userId}")
    public ApiResponse<?> removeMember(
            @PathVariable String id,
            @PathVariable String userId,
            Authentication authentication) {
        String currentUserUuid = authentication.getPrincipal().toString();
        rideParticipantService.removeMember(id, userId, currentUserUuid);
        return ApiResponse.success(null, "Rider removed successfully");
    }

}
