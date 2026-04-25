package com.ridersclub.admin.kafka;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AuditLogEvent {
    private String action;
    private Long adminId;
    private Long targetId;
    private String timestamp;
}
