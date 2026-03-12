package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.RideGroup;

@Repository
public interface RideGroupRepository extends JpaRepository<RideGroup, Long> {
    RideGroup findByRide_Id(String rideId);

    Optional<RideGroup> findByUuid(String uuid);

    List<RideGroup> findByParentGroupUuid(String parentGroupUuid);
}
