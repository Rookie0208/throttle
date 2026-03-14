package com.ridersclub.user.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.user.entity.UserFollow;

@Repository
public interface UserFollowRepository extends JpaRepository<UserFollow, Long> {
    long countByFollowerId(Long followerId);

    long countByFollowingId(Long followingId);
}
