package com.ridersclub.admin.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * A single slice in a categorical breakdown chart (e.g. ride statuses, report types).
 * Generic enough to be reused for any enum-grouped count query.
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class AdminBreakdownPointDTO {
    /** The category label (enum name) */
    private String label;
    private long count;
}
