package com.ridersclub.admin.service;

import com.ridersclub.admin.dto.request.QueryRequestDTO;
import com.ridersclub.admin.dto.response.QueryResponseDTO;
import com.ridersclub.admin.kafka.AuditLogEvent;
import com.ridersclub.admin.kafka.AuditProducer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;

import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminQueryService {

    private final JdbcTemplate jdbcTemplate;
    private final AuditProducer auditProducer;
    private final MeterRegistry meterRegistry;

    private static final int MAX_ROWS = 500;

    public QueryResponseDTO executeQuery(Long adminId, QueryRequestDTO request) {
        String query = request.getQuery();
        log.info("ADMIN action=EXECUTE_QUERY adminId={} query={}", adminId, query);

        long startTime = System.currentTimeMillis();

        try {
            return jdbcTemplate.execute((java.sql.Statement stmt) -> {
                stmt.setMaxRows(MAX_ROWS);
                boolean isResultSet = false;
                try {
                     isResultSet = stmt.execute(query);
                } catch (SQLException e) {
                    return buildErrorResponse(e, startTime);
                }

                long executionTime = System.currentTimeMillis() - startTime;

                if (isResultSet) {
                    try (var resultSet = stmt.getResultSet()) {
                        ResultSetMetaData metaData = resultSet.getMetaData();
                        int columnCount = metaData.getColumnCount();
                        
                        List<String> columns = new ArrayList<>();
                        for (int i = 1; i <= columnCount; i++) {
                            columns.add(metaData.getColumnLabel(i));
                        }

                        List<Map<String, Object>> data = new ArrayList<>();
                        while (resultSet.next()) {
                            Map<String, Object> row = new LinkedHashMap<>();
                            for (int i = 1; i <= columnCount; i++) {
                                row.put(columns.get(i - 1), resultSet.getObject(i));
                            }
                            data.add(row);
                        }

                        publishAudit(adminId, query);
                        log.info("ADMIN action=EXECUTE_QUERY status=SUCCESS_SELECT adminId={} rowsReturned={} duration={}ms", adminId, data.size(), executionTime);

                        return QueryResponseDTO.builder()
                                .isResultSet(true)
                                .columns(columns)
                                .data(data)
                                .rowsAffected(0)
                                .executionTimeMs(executionTime)
                                .build();
                    }
                } else {
                    int updateCount = stmt.getUpdateCount();
                    publishAudit(adminId, query);
                    
                    log.info("ADMIN action=EXECUTE_QUERY status=SUCCESS_UPDATE adminId={} updateCount={} duration={}ms", adminId, updateCount, executionTime);

                    return QueryResponseDTO.builder()
                            .isResultSet(false)
                            .rowsAffected(updateCount)
                            .executionTimeMs(executionTime)
                            .build();
                }
            });
        } catch (Exception e) {
            log.error("ADMIN action=EXECUTE_QUERY status=ERROR adminId={} error=\"{}\"", adminId, e.getMessage(), e);
            Counter.builder("admin_query_failed_total")
                .description("Total number of failed admin queries")
                .register(meterRegistry)
                .increment();
            return buildErrorResponse(e, startTime);
        }
    }

    private QueryResponseDTO buildErrorResponse(Exception e, long startTime) {
        return QueryResponseDTO.builder()
                .isResultSet(false)
                .executionTimeMs(System.currentTimeMillis() - startTime)
                .error(e.getMessage() != null ? e.getMessage() : e.toString())
                .build();
    }

    private void publishAudit(Long adminId, String query) {
        String logQuery = query.length() > 50 ? query.substring(0, 50) + "..." : query;
        log.info("AUDIT_EVENT action=EXECUTE_QUERY adminId={} querySnippet={}", adminId, logQuery);
        AuditLogEvent event = AuditLogEvent.builder()
                .action("EXECUTE_QUERY: " + logQuery)
                .adminId(adminId)
                .targetId(-1L)
                .timestamp(LocalDateTime.now().toString())
                .build();
        auditProducer.publishAuditLog(event);

        Counter.builder("admin_actions_total")
               .tag("action", "EXECUTE_QUERY")
               .description("Total number of admin actions taken")
               .register(meterRegistry)
               .increment();
    }
}
