package com.ridersclub.admin.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Represents a single data point in a time-series growth chart.
 * Used by the dashboard to render User Growth and Ride Activity trend lines.
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class AdminGrowthPointDTO {
    /** ISO-8601 date string, e.g. "2026-04-26" */
    private String date;
    private long count;
}
