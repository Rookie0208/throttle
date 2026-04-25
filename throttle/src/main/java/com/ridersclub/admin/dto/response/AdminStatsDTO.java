package com.ridersclub.admin.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AdminStatsDTO {
    private long totalUsers;
    private long activeUsers;
    private long totalRides;
    private long pendingReports;
}
