package com.ridersclub.admin.controller;

import com.ridersclub.admin.dto.response.AdminUserDTO;
import com.ridersclub.admin.dto.response.AdminRideDTO;
import com.ridersclub.admin.dto.response.AdminStatsDTO;
import com.ridersclub.admin.dto.response.AdminReportDTO;
import com.ridersclub.admin.dto.response.AdminAuditDTO;
import com.ridersclub.admin.security.AdminSecurityContext;
import com.ridersclub.admin.service.AdminService;
import com.ridersclub.admin.service.ElasticsearchAuditService;
import com.ridersclub.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;

import com.ridersclub.admin.dto.request.QueryRequestDTO;
import com.ridersclub.admin.dto.response.QueryResponseDTO;
import com.ridersclub.admin.service.AdminQueryService;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final ElasticsearchAuditService elasticsearchAuditService;
    private final AdminQueryService adminQueryService;

    // A mock method to get current admin ID, typically derived from Security Context
    private Long getCurrentAdminId() {
        return 1L; // Hardcoded for MVP
    }
    private final AdminSecurityContext adminSecurityContext;

    @GetMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<AdminUserDTO>>> getAllUsers() {
        String currentUserUuid = (String) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllUsers(currentUserUuid), "Users retrieved successfully"));
    }

    @PutMapping("/users/{id}/block")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> blockUser(@PathVariable Long id) {
        adminService.blockUser(adminSecurityContext.getCurrentAdminId(), id);
        return ResponseEntity.ok(ApiResponse.success(null, "User blocked successfully"));
    }

    @PutMapping("/users/{id}/unblock")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> unblockUser(@PathVariable Long id) {
        adminService.unblockUser(adminSecurityContext.getCurrentAdminId(), id);
        return ResponseEntity.ok(ApiResponse.success(null, "User unblocked successfully"));
    }

    @GetMapping("/rides")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<AdminRideDTO>>> getAllRides() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllRides(), "Rides retrieved successfully"));
    }

    @PutMapping("/rides/{id}/cancel")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> cancelRide(@PathVariable Long id) {
        adminService.cancelRide(adminSecurityContext.getCurrentAdminId(), id);
        return ResponseEntity.ok(ApiResponse.success(null, "Ride cancelled successfully"));
    }

    @GetMapping("/stats")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<AdminStatsDTO>> getStats() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getDashboardStats(), "Stats retrieved successfully"));
    }

    /**
     * Returns daily growth time-series for users and rides.
     *
     * @param days  lookback window in days (clamped to [1, 90]); default 14
     */
    @GetMapping("/stats/growth")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<AdminStatsDTO.GrowthStats>> getGrowthStats(
            @RequestParam(defaultValue = "14") int days) {
        int clampedDays = Math.max(1, Math.min(days, 90));
        return ResponseEntity.ok(ApiResponse.success(adminService.getGrowthStats(clampedDays), "Growth stats retrieved"));
    }

    /**
     * Returns a comprehensive analytics snapshot: user/ride/report breakdowns.
     * The frontend fetches this once on mount; no polling needed for stable counts.
     */
    @GetMapping("/stats/analytics")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<com.ridersclub.admin.dto.response.AdminAnalyticsDTO>> getAnalytics() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAnalytics(), "Analytics retrieved"));
    }

    @GetMapping("/reports")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<AdminReportDTO>>> getAllReports() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllReports(), "Reports retrieved successfully"));
    }

    @PutMapping("/reports/{id}/resolve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> resolveReport(@PathVariable Long id, @RequestParam(required = false, defaultValue = "Resolved by admin.") String note) {
        adminService.resolveReport(adminSecurityContext.getCurrentAdminId(), id, note);
        return ResponseEntity.ok(ApiResponse.success(null, "Report resolved successfully"));
    }

    @PutMapping("/reports/{id}/dismiss")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> dismissReport(
            @PathVariable Long id,
            @RequestParam(required = false, defaultValue = "Dismissed — no action required.") String note) {
        adminService.dismissReport(adminSecurityContext.getCurrentAdminId(), id, note);
        return ResponseEntity.ok(ApiResponse.success(null, "Report dismissed successfully"));
    }

    @PutMapping("/users/{id}/role")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> updateUserRole(@PathVariable Long id, @RequestParam String role) {
        adminService.updateUserRole(adminSecurityContext.getCurrentAdminId(), id, role);
        return ResponseEntity.ok(ApiResponse.success(null, "User role completely aligned"));
    }

    @GetMapping("/audit-logs")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<AdminAuditDTO>>> getAuditLogs() {
        return ResponseEntity.ok(ApiResponse.success(elasticsearchAuditService.getAuditLogs(), "Audit logs retrieved from Elasticsearch"));
    }

    @PostMapping("/execute-query")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<QueryResponseDTO>> executeQuery(@Valid @RequestBody QueryRequestDTO request) {
        QueryResponseDTO response = adminQueryService.executeQuery(adminSecurityContext.getCurrentAdminId(), request);
        return ResponseEntity.ok(ApiResponse.success(response, "Query executed"));
    }
}
