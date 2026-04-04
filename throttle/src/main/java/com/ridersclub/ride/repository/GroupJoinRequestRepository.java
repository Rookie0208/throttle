package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.common.enums.GroupJoinRequestStatus;
import com.ridersclub.ride.entity.GroupJoinRequest;

@Repository
public interface GroupJoinRequestRepository extends JpaRepository<GroupJoinRequest, Long> {
    Optional<GroupJoinRequest> findByGroup_IdAndUser_IdAndStatus(Long groupId, Long userId, GroupJoinRequestStatus status);
    List<GroupJoinRequest> findByGroup_IdAndStatusOrderByCreatedAtAsc(Long groupId, GroupJoinRequestStatus status);
    void deleteByGroup_IdAndUser_Id(Long groupId, Long userId);
}
