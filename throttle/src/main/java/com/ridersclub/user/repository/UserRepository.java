package com.ridersclub.user.repository;

import java.util.Optional;
import java.util.List;
import java.time.LocalDateTime;

import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.ridersclub.user.entity.User;
import com.ridersclub.admin.dto.response.AdminGrowthPointDTO;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    boolean existsByUsername(String username);

    Optional<User> findByUuid(String uuid);

    boolean existsByRiderId(String riderId);

    Optional<User> findByRiderId(String riderId);

    @Query("""
            select u from User u
            where lower(concat(coalesce(u.firstName, ''), ' ', coalesce(u.lastName, ''))) like lower(concat('%', :query, '%'))
               or lower(coalesce(u.riderId, '')) like lower(concat('%', :query, '%'))
               or lower(coalesce(u.email, '')) like lower(concat('%', :query, '%'))
            """)
    List<User> searchByProfileFields(@Param("query") String query);

    /**
     * Returns daily signup counts for the last N days, ordered ascending.
     * Uses JPQL FUNCTION('DATE', ...) for DB-agnostic date truncation.
     */
    @Query("""
            SELECT new com.ridersclub.admin.dto.response.AdminGrowthPointDTO(
                CAST(FUNCTION('DATE', u.createdAt) AS string),
                COUNT(u)
            )
            FROM User u
            WHERE u.createdAt >= :since
            GROUP BY FUNCTION('DATE', u.createdAt)
            ORDER BY FUNCTION('DATE', u.createdAt) ASC
            """)
    List<AdminGrowthPointDTO> countUsersByDate(@Param("since") LocalDateTime since);

    /**
     * Efficient server-side count of active users without loading all entities.
     */
    @Query("SELECT COUNT(u) FROM User u WHERE u.active = true")
    long countActiveUsers();
}
