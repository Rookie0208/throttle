package com.ridersclub.admin.dto.response;

import lombok.Builder;
import lombok.Data;
import java.util.List;

/**
 * Comprehensive platform analytics payload returned by GET /admin/stats/analytics.
 * Aggregates all categorical breakdowns the dashboard needs in a single request.
 */
@Data
@Builder
public class AdminAnalyticsDTO {

    // ── User Metrics ──────────────────────────────────────────────────────────
    private long totalUsers;
    private long activeUsers;
    private long blockedUsers;

    // ── Ride Metrics ──────────────────────────────────────────────────────────
    private long totalRides;
    private long completedRides;
    private long activeRides;

    /** Ride counts grouped by Status enum */
    private List<AdminBreakdownPointDTO> ridesByStatus;

    /** Ride counts grouped by RideType (SOLO / GROUP) */
    private List<AdminBreakdownPointDTO> ridesByType;

    // ── Report Metrics ────────────────────────────────────────────────────────
    private long totalReports;
    private long pendingReports;
    private long resolvedReports;

    /** Report counts grouped by ReportStatus */
    private List<AdminBreakdownPointDTO> reportsByStatus;

    /** Report counts grouped by ReportType (USER / RIDE / SYSTEM) */
    private List<AdminBreakdownPointDTO> reportsByType;
}
