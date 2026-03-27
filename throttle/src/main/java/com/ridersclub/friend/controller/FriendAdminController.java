package com.ridersclub.friend.controller;

import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.friend.service.FriendAdminService;
import com.ridersclub.friend.service.FriendService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Map;

/**
 * Admin/operational endpoints for graph management and diagnostics.
 * These are NOT part of the public API contract and are for internal use only.
 */
@RestController
@RequestMapping("/api/v1/friends")
@RequiredArgsConstructor
@Slf4j
public class FriendAdminController {

    private final FriendAdminService friendAdminService;
    private final FriendService friendService;

    @PostMapping("/sync-graph")
    public ResponseEntity<ApiResponse<Void>> syncGraph() {
        friendAdminService.syncGraphData();
        return ResponseEntity.ok(ApiResponse.success(null, "Graph data synchronized"));
    }

    @GetMapping("/debug/graph")
    public ResponseEntity<ApiResponse<Map<String, Object>>> debugGraph(
            @RequestParam(value = "userId", required = false) String userId,
            @RequestParam(value = "otherUserId", required = false) String otherUserId,
            Principal principal) {

        String targetId = userId;
        if (targetId == null && principal != null) {
            targetId = principal.getName();
        }
        if (targetId == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.failure(null, "userId is required"));
        }

        Map<String, Object> debugInfo = friendAdminService.getGraphDebugInfo(targetId);

        if (otherUserId != null && !otherUserId.isBlank()) {
            Integer mutualCount = friendService.getMutualFriendsCount(targetId, otherUserId);
            debugInfo.put("mutualCountWithOther", mutualCount);
            debugInfo.put("otherUserId", otherUserId);

            Map<String, Object> otherDebug = friendAdminService.getGraphDebugInfo(otherUserId);
            debugInfo.put("otherNodeExists", otherDebug.get("userNodeExists"));
            debugInfo.put("otherNeo4jFriendCount", otherDebug.get("neo4jFriendCount"));

            log.info("Debug Graph: Mutual count between {} and {} is {}", targetId, otherUserId, mutualCount);
        }

        return ResponseEntity.ok(ApiResponse.success(debugInfo, "Graph debug info"));
    }
}
