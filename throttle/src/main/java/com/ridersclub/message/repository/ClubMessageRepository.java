package com.ridersclub.message.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.message.entity.ClubMessage;

@Repository
public interface ClubMessageRepository extends JpaRepository<ClubMessage, Long> {
    List<ClubMessage> findTop50ByClub_UuidAndSubgroupIsNullOrderByCreatedAtDesc(String clubUuid);
    List<ClubMessage> findTop50BySubgroup_UuidOrderByCreatedAtDesc(String subgroupUuid);
}
