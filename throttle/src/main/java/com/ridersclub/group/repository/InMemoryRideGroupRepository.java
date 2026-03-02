package com.ridersclub.group.repository;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.RideGroup;

@Repository
public class InMemoryRideGroupRepository implements RideGroupRepository {

   private final Map<String, RideGroup> groupsById = new HashMap<>();
    private final Map<String, String> rideToGroup = new HashMap<>();

    // Save or update group
    public RideGroup save(RideGroup group) {
        groupsById.put(group.getId(), group);
        rideToGroup.put(group.getRideId(), group.getId());
        return group;
    }

    // Find group by ID
    public Optional<RideGroup> findById(String id) {
        return Optional.ofNullable(groupsById.get(id));
    }

    // Find group by rideId
    public Optional<RideGroup> findByRideId(String rideId) {
        String groupId = rideToGroup.get(rideId);
        if (groupId == null) return Optional.empty();
        return Optional.ofNullable(groupsById.get(groupId));
    }

    // List all groups for given rideIds
    public List<RideGroup> findByRideIdIn(List<String> rideIds) {
        List<RideGroup> list = new ArrayList<>();
        for (String rideId : rideIds) {
            findByRideId(rideId).ifPresent(list::add);
        }
        return list;
    }

    // Delete group by rideId
    public void deleteByRideId(String rideId) {
        String groupId = rideToGroup.remove(rideId);
        if (groupId != null) {
            groupsById.remove(groupId);
        }
    }
}
