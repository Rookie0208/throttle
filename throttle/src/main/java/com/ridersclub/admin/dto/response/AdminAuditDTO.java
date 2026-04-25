package com.ridersclub.admin.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AdminAuditDTO {
    private Long id;
    private String esDocId;  // Elasticsearch document _id
    private String action;
    private Long adminId;
    private Long targetId;
    private String timestamp;
}
