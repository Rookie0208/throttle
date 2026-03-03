package com.ridersclub.ride.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.ride.entity.RideStats;

@Repository
public interface RideStatsRepository extends JpaRepository<RideParticipant, Long> {
RideStats save(RideStats stats);
    List<RideStats> findByUser_Id(String userId);
}
