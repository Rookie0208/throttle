package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.ClubMember;

@Repository
public interface ClubMemberRepository extends JpaRepository<ClubMember, Long> {
    List<ClubMember> findByClub_Id(Long clubId);
    List<ClubMember> findByUser_Uuid(String userUuid);
    Optional<ClubMember> findByClub_IdAndUser_Id(Long clubId, Long userId);
    boolean existsByClub_IdAndUser_Id(Long clubId, Long userId);
    long countByClub_Id(Long clubId);
    void deleteByClub_IdAndUser_Id(Long clubId, Long userId);
}
