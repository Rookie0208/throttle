package com.ridersclub.common.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * HTTP Access Log Filter
 *
 * Logs every inbound HTTP request as a structured JSON line in the ACCESS_LOG stream.
 * Promtail picks this up from Docker stdout and ships to Loki.
 *
 * Example output:
 * {
 *   "stream": "access",
 *   "method": "POST",
 *   "path": "/api/v1/auth/login",
 *   "status": 200,
 *   "duration_ms": 43,
 *   "userId": "uuid-xyz",
 *   "ip": "192.168.1.1"
 * }
 */
@Component
public class AccessLogFilter extends OncePerRequestFilter {

    // Dedicated logger — routed to ACCESS_JSON appender in logback-spring.xml
    private static final Logger ACCESS_LOG = LoggerFactory.getLogger("ACCESS_LOG");

    // Skip actuator health pings and static resources
    private static final String[] SKIP_PATHS = {
        "/api/health", "/actuator/health", "/actuator/prometheus",
        "/favicon.ico", "/swagger-ui", "/v3/api-docs"
    };

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String uri = request.getRequestURI();
        for (String skip : SKIP_PATHS) {
            if (uri.startsWith(skip)) return true;
        }
        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        long start = System.currentTimeMillis();
        try {
            chain.doFilter(request, response);
        } finally {
            long duration = System.currentTimeMillis() - start;
            String userId = extractUserId();
            String ip = getClientIp(request);

            // All fields will be serialised as JSON by LogstashEncoder
            ACCESS_LOG.info("",
                net.logstash.logback.argument.StructuredArguments.entries(
                    java.util.Map.of(
                        "method",      request.getMethod(),
                        "path",        request.getRequestURI(),
                        "status",      response.getStatus(),
                        "duration_ms", duration,
                        "userId",      userId != null ? userId : "anonymous",
                        "ip",          ip,
                        "userAgent",   request.getHeader("User-Agent") != null
                                           ? request.getHeader("User-Agent") : ""
                    )
                )
            );
        }
    }

    private String extractUserId() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.isAuthenticated() && auth.getPrincipal() instanceof String) {
                return (String) auth.getPrincipal();
            }
        } catch (Exception ignored) {}
        return null;
    }

    private String getClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
