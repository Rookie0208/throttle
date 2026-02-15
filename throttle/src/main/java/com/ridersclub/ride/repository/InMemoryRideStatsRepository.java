package com.ridersclub.ride.repository;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.RideStats;

@Repository
public class InMemoryRideStatsRepository implements RideStatsRepository {
private final List<RideStats> list = new CopyOnWriteArrayList<>();

    @Override
    public RideStats save(RideStats stats) {
        stats.setId(UUID.randomUUID().toString());
        list.add(stats);
        return stats;
    }

    @Override
    public List<RideStats> findByUserId(String userId) {
        return list.stream().filter(s -> s.getUserId().equals(userId)).toList();
    }
}
