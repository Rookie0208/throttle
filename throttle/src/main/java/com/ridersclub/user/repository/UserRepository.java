package com.ridersclub.user.repository;

import java.util.Optional;
import java.util.List;

import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.ridersclub.user.entity.User;

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
}
