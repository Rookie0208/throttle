package com.ridersclub.admin.service;

import com.ridersclub.admin.dto.response.AdminUserDTO;
import com.ridersclub.admin.dto.response.AdminRideDTO;
import com.ridersclub.admin.dto.response.AdminStatsDTO;
import com.ridersclub.admin.dto.response.AdminReportDTO;
import com.ridersclub.admin.dto.response.AdminAuditDTO;
import com.ridersclub.admin.dto.response.AdminGrowthPointDTO;
import com.ridersclub.admin.dto.response.AdminAnalyticsDTO;
import com.ridersclub.admin.entity.Report;
import com.ridersclub.admin.entity.ReportStatus;
import com.ridersclub.admin.repository.ReportRepository;
import com.ridersclub.admin.kafka.AuditLogEvent;
import com.ridersclub.admin.kafka.AuditProducer;
import com.ridersclub.common.enums.Role;
import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;
import com.ridersclub.common.exception.UserNotFoundException;
import com.ridersclub.auth.service.TokenBlacklistService;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final RideRepository rideRepository;
    private final ReportRepository reportRepository;
    private final AuditProducer auditProducer;
    private final MeterRegistry meterRegistry;
    private final TokenBlacklistService tokenBlacklistService;

    public List<AdminUserDTO> getAllUsers(String excludeUuid) {
        return userRepository.findAll().stream()
            .filter(user -> excludeUuid == null || user.getUuid() == null || !user.getUuid().toString().equals(excludeUuid))
            .map(user ->
            AdminUserDTO.builder()
                .id(user.getId())
                .username(user.getUsername())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .active(user.isActive())
                .createdAt(user.getCreatedAt())
                .build()
        ).collect(Collectors.toList());
    }

    @Transactional
    public void blockUser(Long currentAdminId, Long targetUserId) {
        log.info("ADMIN action=BLOCK_USER adminId={} targetUserId={}", currentAdminId, targetUserId);
        User user = userRepository.findById(targetUserId)
            .orElseThrow(() -> new UserNotFoundException("User not found"));
        user.setActive(false);
        userRepository.save(user);
        tokenBlacklistService.blacklistUser(user.getUuid().toString());
        publishAudit("BLOCK_USER", currentAdminId, targetUserId);
        log.info("ADMIN action=BLOCK_USER status=SUCCESS adminId={} targetUserId={}", currentAdminId, targetUserId);
    }

    @Transactional
    public void unblockUser(Long currentAdminId, Long targetUserId) {
        log.info("ADMIN action=UNBLOCK_USER adminId={} targetUserId={}", currentAdminId, targetUserId);
        User user = userRepository.findById(targetUserId)
            .orElseThrow(() -> new UserNotFoundException("User not found"));
        user.setActive(true);
        userRepository.save(user);
        tokenBlacklistService.unblacklistUser(user.getUuid().toString());
        publishAudit("UNBLOCK_USER", currentAdminId, targetUserId);
        log.info("ADMIN action=UNBLOCK_USER status=SUCCESS adminId={} targetUserId={}", currentAdminId, targetUserId);
    }

    public List<AdminRideDTO> getAllRides() {
        return rideRepository.findAll().stream().map(ride ->
            AdminRideDTO.builder()
                .id(ride.getId())
                .title(ride.getTitle())
                .status(ride.getStatus().name())
                .rideType(ride.getRideType().name())
                .createdBy(ride.getCreatedBy().getId())
                .startTime(ride.getStartTime())
                .build()
        ).collect(Collectors.toList());
    }

    @Transactional
    public void cancelRide(Long currentAdminId, Long rideId) {
        log.info("ADMIN action=CANCEL_RIDE adminId={} rideId={}", currentAdminId, rideId);
        rideRepository.findById(rideId)
            .orElseThrow(() -> new RuntimeException("Ride not found"));
        publishAudit("CANCEL_RIDE", currentAdminId, rideId);
        log.info("ADMIN action=CANCEL_RIDE status=SUCCESS adminId={} rideId={}", currentAdminId, rideId);
    }

    @Transactional
    public void updateUserRole(Long currentAdminId, Long targetUserId, String newRole) {
        log.info("ADMIN action=UPDATE_ROLE adminId={} targetUserId={} newRole={}", currentAdminId, targetUserId, newRole);
        User user = userRepository.findById(targetUserId)
            .orElseThrow(() -> new UserNotFoundException("User not found"));
        user.setRole(Role.valueOf(newRole.toUpperCase()));
        userRepository.save(user);
        publishAudit("UPDATE_ROLE_" + newRole, currentAdminId, targetUserId);
        log.info("ADMIN action=UPDATE_ROLE status=SUCCESS adminId={} targetUserId={} newRole={}", currentAdminId, targetUserId, newRole);
    }

    public AdminStatsDTO getDashboardStats() {
        long totalUsers = userRepository.count();
        long activeUsers = userRepository.findAll().stream().filter(User::isActive).count();
        long totalRides = rideRepository.count();
        long pendingReports = reportRepository.findByStatusOrderByCreatedAtDesc(ReportStatus.PENDING).size();

        return AdminStatsDTO.builder()
            .totalUsers(totalUsers)
            .activeUsers(activeUsers)
            .totalRides(totalRides)
            .pendingReports(pendingReports)
            .build();
    }

    /**
     * Returns daily growth data points for users and rides over the last {@code days} days.
     * Each list is ordered chronologically (oldest → newest) for direct use in front-end charts.
     *
     * @param days number of past days to include (e.g. 14 for a 2-week window)
     */
    public AdminStatsDTO.GrowthStats getGrowthStats(int days) {
        LocalDateTime userSince = LocalDateTime.now().minusDays(days);
        OffsetDateTime rideSince = OffsetDateTime.now().minusDays(days);

        List<AdminGrowthPointDTO> userGrowth = userRepository.countUsersByDate(userSince);
        List<AdminGrowthPointDTO> rideGrowth = rideRepository.countRidesByDate(rideSince);

        return new AdminStatsDTO.GrowthStats(userGrowth, rideGrowth);
    }

    /**
     * Returns a comprehensive analytics snapshot for the admin dashboard.
     * All data is fetched via group-by JPQL queries — no entity-level iteration.
     */
    public AdminAnalyticsDTO getAnalytics() {
        // ── User metrics ──────────────────────────────────────────────────────
        long totalUsers   = userRepository.count();
        long activeUsers  = userRepository.countActiveUsers();
        long blockedUsers = totalUsers - activeUsers;

        // ── Ride metrics ──────────────────────────────────────────────────────
        long totalRides     = rideRepository.count();
        long completedRides = rideRepository.countByStatusEnum(com.ridersclub.common.enums.Status.COMPLETED);
        long activeRides    = rideRepository.countByStatusEnum(com.ridersclub.common.enums.Status.ACTIVE);

        // ── Report metrics ────────────────────────────────────────────────────
        long totalReports    = reportRepository.count();
        long pendingReports  = reportRepository.countByStatusEnum(com.ridersclub.admin.entity.ReportStatus.PENDING);
        long resolvedReports = reportRepository.countByStatusEnum(com.ridersclub.admin.entity.ReportStatus.RESOLVED);

        return AdminAnalyticsDTO.builder()
                .totalUsers(totalUsers)
                .activeUsers(activeUsers)
                .blockedUsers(blockedUsers)
                .totalRides(totalRides)
                .completedRides(completedRides)
                .activeRides(activeRides)
                .ridesByStatus(rideRepository.countByStatus())
                .ridesByType(rideRepository.countByRideType())
                .totalReports(totalReports)
                .pendingReports(pendingReports)
                .resolvedReports(resolvedReports)
                .reportsByStatus(reportRepository.countByStatus())
                .reportsByType(reportRepository.countByType())
                .build();
    }

    public List<AdminReportDTO> getAllReports() {
        return reportRepository.findAll().stream().map(r ->
            AdminReportDTO.builder()
                .id(r.getId())
                .reporterId(r.getReporterId())
                .targetId(r.getTargetId())
                .type(r.getType().name())
                .reason(r.getReason())
                .status(r.getStatus().name())
                .createdAt(r.getCreatedAt())
                .resolvedAt(r.getResolvedAt())
                .resolutionNote(r.getResolutionNote())
                .build()
        ).collect(Collectors.toList());
    }

    @Transactional
    public void resolveReport(Long currentAdminId, Long reportId, String note) {
        log.info("ADMIN action=RESOLVE_REPORT adminId={} reportId={}", currentAdminId, reportId);
        Report report = reportRepository.findById(reportId)
            .orElseThrow(() -> new RuntimeException("Report not found"));
        report.setStatus(ReportStatus.RESOLVED);
        report.setResolvedAt(LocalDateTime.now());
        report.setResolutionNote(note);
        reportRepository.save(report);
        publishAudit("RESOLVE_REPORT", currentAdminId, reportId);
        log.info("ADMIN action=RESOLVE_REPORT status=SUCCESS adminId={} reportId={}", currentAdminId, reportId);
    }

    private void publishAudit(String action, Long adminId, Long targetId) {
        log.info("AUDIT_EVENT action={} adminId={} targetId={}", action, adminId, targetId);
        String timestamp = java.time.Instant.now().toString();
        AuditLogEvent event = AuditLogEvent.builder()
            .action(action)
            .adminId(adminId)
            .targetId(targetId)
            .timestamp(timestamp)
            .build();
        auditProducer.publishAuditLog(event);
        Counter.builder("admin_actions_total")
               .tag("action", action)
               .description("Total number of admin actions taken")
               .register(meterRegistry)
               .increment();
    }
}
