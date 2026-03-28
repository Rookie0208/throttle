package com.ridersclub.friend.controller;

import com.ridersclub.common.Utils.ApiConstants;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.friend.dto.request.FriendRequestPayload;
import com.ridersclub.friend.dto.response.FriendDto;
import com.ridersclub.friend.dto.response.FriendRelationshipDto;
import com.ridersclub.friend.dto.response.PendingRequestDto;
import com.ridersclub.friend.service.FriendService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping(ApiConstants.Friends.BASE)
@RequiredArgsConstructor
@Slf4j
public class FriendController {

    private static final String MUTUAL_PATH = "/friends/mutual/{targetUserId}";
    private static final String LOG_PREFIX = "FRIEND_API";

    private final FriendService friendService;

    @PostMapping(ApiConstants.Friends.REQUEST)
    public ResponseEntity<ApiResponse<Void>> sendFriendRequest(
            @Valid @RequestBody FriendRequestPayload payload,
            Principal principal) {
        log.info("{} action=send_request actor={} target={}", LOG_PREFIX, principal.getName(), payload.getReceiverUuid());
        friendService.sendRequest(principal.getName(), payload.getReceiverUuid());
        return ResponseEntity.ok(ApiResponse.success(null, "Friend request sent successfully"));
    }

    @PostMapping(ApiConstants.Friends.ACCEPT)
    public ResponseEntity<ApiResponse<Void>> acceptFriendRequest(
            @PathVariable("requestId") Long requestId,
            Principal principal) {
        log.info("{} action=accept_request actor={} requestId={}", LOG_PREFIX, principal.getName(), requestId);
        friendService.acceptRequest(principal.getName(), requestId);
        return ResponseEntity.ok(ApiResponse.success(null, "Friend request accepted"));
    }

    @PostMapping(ApiConstants.Friends.REJECT)
    public ResponseEntity<ApiResponse<Void>> rejectFriendRequest(
            @PathVariable("requestId") Long requestId,
            Principal principal) {
        log.info("{} action=reject_request actor={} requestId={}", LOG_PREFIX, principal.getName(), requestId);
        friendService.rejectRequest(principal.getName(), requestId);
        return ResponseEntity.ok(ApiResponse.success(null, "Friend request rejected"));
    }

    @DeleteMapping(ApiConstants.Friends.UNFRIEND)
    public ResponseEntity<ApiResponse<Void>> unfriend(
            @PathVariable("targetUserId") String targetUserId,
            Principal principal) {
        log.info("{} action=unfriend actor={} target={}", LOG_PREFIX, principal.getName(), targetUserId);
        friendService.unfriend(principal.getName(), targetUserId);
        return ResponseEntity.ok(ApiResponse.success(null, "Friend removed successfully"));
    }

    @GetMapping(ApiConstants.Friends.LIST)
    public ResponseEntity<ApiResponse<List<FriendDto>>> getFriends(
            @PathVariable("userId") String userId) {
        log.debug("{} action=get_friends userId={}", LOG_PREFIX, userId);
        return ResponseEntity.ok(ApiResponse.success(friendService.getFriends(userId), "Fetched friends list"));
    }

    @GetMapping(ApiConstants.Friends.PENDING_REQUESTS)
    public ResponseEntity<ApiResponse<List<PendingRequestDto>>> getPendingRequests(Principal principal) {
        log.debug("{} action=get_pending_requests actor={}", LOG_PREFIX, principal.getName());
        return ResponseEntity.ok(ApiResponse.success(
                friendService.getPendingRequests(principal.getName()), "Fetched pending requests"));
    }

    @GetMapping(ApiConstants.Friends.RECOMMENDATIONS)
    public ResponseEntity<ApiResponse<List<FriendDto>>> getFriendRecommendations(
            @PathVariable("userId") String userId) {
        log.debug("{} action=get_recommendations userId={}", LOG_PREFIX, userId);
        return ResponseEntity.ok(ApiResponse.success(
                friendService.getRecommendations(userId), "Fetched friend recommendations"));
    }

    @GetMapping(ApiConstants.Friends.RELATIONSHIP)
    public ResponseEntity<ApiResponse<FriendRelationshipDto>> getRelationshipStatus(
            @PathVariable("targetUserId") String targetUserId,
            Principal principal) {
        log.debug("{} action=get_relationship_status actor={} target={}", LOG_PREFIX, principal.getName(), targetUserId);
        return ResponseEntity.ok(ApiResponse.success(
                friendService.getRelationshipStatus(principal.getName(), targetUserId),
                "Fetched friendship status"));
    }

    @GetMapping(MUTUAL_PATH)
    public ResponseEntity<ApiResponse<Integer>> getMutualFriendsCount(
            @PathVariable("targetUserId") String targetUserId,
            Principal principal) {
        log.debug("{} action=get_mutual_count actor={} target={}", LOG_PREFIX, principal.getName(), targetUserId);
        return ResponseEntity.ok(ApiResponse.success(
                friendService.getMutualFriendsCount(principal.getName(), targetUserId),
                "Mutual friends calculated"));
    }
}
