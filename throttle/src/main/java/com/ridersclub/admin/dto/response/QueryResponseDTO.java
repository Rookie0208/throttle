package com.ridersclub.admin.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QueryResponseDTO {
    private boolean isResultSet;
    private List<String> columns;
    private List<Map<String, Object>> data;
    private int rowsAffected;
    private long executionTimeMs;
    private String error;
}
