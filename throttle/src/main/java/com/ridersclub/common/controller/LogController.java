package com.ridersclub.common.controller;

import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Receives structured log entries from the Flutter mobile app and routes them
 * through the standard SLF4J pipeline (JSON → stdout → Loki → Grafana).
 *
 * Flutter sends POST /api/v1/logs with body:
 *   { "level": "INFO|WARN|ERROR|DEBUG", "message": "...", "traceId": "optional" }
 *
 * Logs appear in Grafana with label: stream="mobile"
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/logs")
public class LogController {

    private static final org.slf4j.Logger mobileLog =
            org.slf4j.LoggerFactory.getLogger("MOBILE_LOG");

    @PostMapping
    public ResponseEntity<Void> receiveFrontendLog(@RequestBody Map<String, Object> payload) {
        String level   = (String) payload.getOrDefault("level", "INFO");
        String message = (String) payload.getOrDefault("message", "");
        String traceId = (String) payload.getOrDefault("traceId", "");

        // Inject optional client-side traceId into MDC so it appears in JSON output
        try {
            if (traceId != null && !traceId.isBlank()) {
                MDC.put("clientTraceId", traceId);
            }

            switch (level.toUpperCase()) {
                case "ERROR" -> mobileLog.error("[Mobile] {}", message);
                case "WARN"  -> mobileLog.warn("[Mobile] {}", message);
                case "DEBUG" -> mobileLog.debug("[Mobile] {}", message);
                default      -> mobileLog.info("[Mobile] {}", message);
            }
        } finally {
            MDC.remove("clientTraceId");
        }

        return ResponseEntity.ok().build();
    }
}
