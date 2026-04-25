package com.ridersclub.admin.service;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch.core.SearchResponse;
import co.elastic.clients.elasticsearch.core.search.Hit;
import com.ridersclub.admin.dto.response.AdminAuditDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ElasticsearchAuditService {

    private final ElasticsearchClient elasticsearchClient;

    private static final String INDEX_PATTERN = "admin-audit-logs-*";

    @SuppressWarnings("unchecked")
    public List<AdminAuditDTO> getAuditLogs() {
        try {
            SearchResponse<Map> response = elasticsearchClient.search(s -> s
                    .index(INDEX_PATTERN)
                    .size(200)
                    .sort(so -> so.field(f -> f.field("timestamp").order(co.elastic.clients.elasticsearch._types.SortOrder.Desc))),
                    Map.class);

            return response.hits().hits().stream()
                    .map(hit -> {
                        Map source = hit.source();
                        if (source == null) return null;
                        // _id is the Elasticsearch document ID (system-generated), not in source
                        String esId = hit.id();
                        Long numericId = null;
                        try { numericId = Long.parseLong(esId); } catch (Exception ignored) {}

                        return AdminAuditDTO.builder()
                                .id(numericId)
                                .action((String) source.get("action"))
                                .adminId(source.get("adminId") instanceof Number ? ((Number) source.get("adminId")).longValue() : null)
                                .targetId(source.get("targetId") instanceof Number ? ((Number) source.get("targetId")).longValue() : null)
                                .timestamp((String) source.get("timestamp"))
                                .esDocId(esId)
                                .build();
                    })
                    .filter(dto -> dto != null)
                    .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Failed to query audit logs from Elasticsearch: {}", e.getMessage());
            return Collections.emptyList();
        }
    }
}
