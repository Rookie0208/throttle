package com.ridersclub.admin.dto.response;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class AdminStatsDTO {
    private long totalUsers;
    private long activeUsers;
    private long totalRides;
    private long pendingReports;

    /**
     * Encapsulates the time-series growth data returned by GET /admin/stats/growth.
     * Using a Java record for concise, immutable data transport.
     */
    public record GrowthStats(
        List<AdminGrowthPointDTO> userGrowth,
        List<AdminGrowthPointDTO> rideGrowth
    ) {}
}
