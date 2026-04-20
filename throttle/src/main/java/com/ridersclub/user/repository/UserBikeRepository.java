package com.ridersclub.user.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.user.entity.UserBike;

@Repository
public interface UserBikeRepository extends JpaRepository<UserBike, Long> {
    List<UserBike> findByUserId(Long userId);
    long countByUserId(Long userId);
    java.util.Optional<UserBike> findByIdAndUserId(Long id, Long userId);
    List<UserBike> findByUserIdOrderByPrimaryDescCreatedAtAsc(Long userId);
}
