package com.ridersclub.ride.repository;

import java.util.List;

import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.ride.entity.RideStats;

@Repository
public interface RideStatsRepository extends org.springframework.data.repository.Repository<RideParticipant, Long> {
RideStats save(RideStats stats);
    List<RideStats> findByUserId(String userId);
}
