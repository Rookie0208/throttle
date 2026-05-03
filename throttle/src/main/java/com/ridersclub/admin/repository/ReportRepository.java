package com.ridersclub.admin.repository;

import com.ridersclub.admin.dto.response.AdminBreakdownPointDTO;
import com.ridersclub.admin.entity.Report;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReportRepository extends JpaRepository<Report, Long> {
    List<Report> findByStatusOrderByCreatedAtDesc(com.ridersclub.admin.entity.ReportStatus status);

    /**
     * Returns count of reports grouped by ReportStatus (PENDING / RESOLVED / DISMISSED).
     */
    @Query("""
            SELECT new com.ridersclub.admin.dto.response.AdminBreakdownPointDTO(
                CAST(r.status AS string),
                COUNT(r)
            )
            FROM Report r
            GROUP BY r.status
            ORDER BY COUNT(r) DESC
            """)
    List<AdminBreakdownPointDTO> countByStatus();

    /**
     * Returns count of reports grouped by ReportType (USER / RIDE / SYSTEM).
     */
    @Query("""
            SELECT new com.ridersclub.admin.dto.response.AdminBreakdownPointDTO(
                CAST(r.type AS string),
                COUNT(r)
            )
            FROM Report r
            GROUP BY r.type
            ORDER BY COUNT(r) DESC
            """)
    List<AdminBreakdownPointDTO> countByType();

    /** Spring Data derived — COUNT WHERE status = :status */
    long countByStatus(com.ridersclub.admin.entity.ReportStatus status);

    /** Alias to avoid ambiguity with the JPQL group-by projection above */
    default long countByStatusEnum(com.ridersclub.admin.entity.ReportStatus status) {
        return countByStatus(status);
    }
}
