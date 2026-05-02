package com.ridersclub.admin.dto.response;

import java.time.Instant;
import java.util.List;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class FrontendResourceAdminDTO {
    private String resourceKey;
    private String source;
    private String updatedBy;
    private Instant updatedAt;
    private List<ResourceEntryDTO> entries;

    @Getter
    @Builder
    public static class ResourceEntryDTO {
        private String key;
        private Object value;
    }
}
