package com.ridersclub.admin.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AdminReportDTO {
    private Long id;
    private Long reporterId;
    private Long targetId;
    private String type;
    private String reason;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime resolvedAt;
    private String resolutionNote;
}
