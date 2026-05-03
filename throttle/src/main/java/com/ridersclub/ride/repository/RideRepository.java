package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;
import java.time.OffsetDateTime;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Ride;
import com.ridersclub.admin.dto.response.AdminGrowthPointDTO;
import com.ridersclub.admin.dto.response.AdminBreakdownPointDTO;

@Repository
public interface RideRepository extends JpaRepository<Ride, Long> {
        Optional<Ride> findById(String id);

        public java.util.List<Ride> findAll();

        @Query("SELECT rp.ride FROM RideParticipant rp WHERE rp.user.uuid = :userUuid")
        List<Ride> findMyRides(@Param("userUuid") String userUuid);

        List<Ride> findByCreatedBy_Id(Long userId);

        Optional<Ride> findByUuid(String uuid);

        List<Ride> findByVisibility(com.ridersclub.common.enums.Visibility visibility);

        // Fetch up to 3 recent completed rides for a given list of ride IDs
        java.util.List<Ride> findTop3ByIdInAndStatusOrderByStartTimeDesc(java.util.List<Long> rideIds,
                        com.ridersclub.common.enums.Status status);

        // Fetch the next upcoming planned ride for a given list of ride IDs
        Optional<Ride> findFirstByIdInAndStatusAndStartTimeAfterOrderByStartTimeAsc(java.util.List<Long> rideIds,
                        com.ridersclub.common.enums.Status status, java.time.LocalDateTime now);

        /**
         * Returns daily ride creation counts for the last N days, ordered ascending.
         */
        @Query("""
                SELECT new com.ridersclub.admin.dto.response.AdminGrowthPointDTO(
                    CAST(FUNCTION('DATE', r.createdAt) AS string),
                    COUNT(r)
                )
                FROM Ride r
                WHERE r.createdAt >= :since
                GROUP BY FUNCTION('DATE', r.createdAt)
                ORDER BY FUNCTION('DATE', r.createdAt) ASC
                """)
        List<AdminGrowthPointDTO> countRidesByDate(@Param("since") OffsetDateTime since);

        /**
         * Returns the count of rides grouped by their Status enum.
         */
        @Query("""
                SELECT new com.ridersclub.admin.dto.response.AdminBreakdownPointDTO(
                    CAST(r.status AS string),
                    COUNT(r)
                )
                FROM Ride r
                GROUP BY r.status
                ORDER BY COUNT(r) DESC
                """)
        List<AdminBreakdownPointDTO> countByStatus();

        /**
         * Returns the count of rides grouped by their RideType (SOLO / GROUP).
         */
        @Query("""
                SELECT new com.ridersclub.admin.dto.response.AdminBreakdownPointDTO(
                    CAST(r.rideType AS string),
                    COUNT(r)
                )
                FROM Ride r
                GROUP BY r.rideType
                ORDER BY COUNT(r) DESC
                """)
        List<AdminBreakdownPointDTO> countByRideType();

        /** Count rides with a specific status — maps to WHERE r.status = :status */
        long countByStatus(com.ridersclub.common.enums.Status status);

        /**
         * Named alias used in AdminService to avoid naming collision with
         * the group-by countByStatus() projection query above.
         */
        default long countByStatusEnum(com.ridersclub.common.enums.Status status) {
            return countByStatus(status);
        }
}
