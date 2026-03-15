package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.user.entity.User;

@Repository
public interface RideGroupRepository extends JpaRepository<RideGroup, Long> {
    RideGroup findByRide_Id(String rideId);

    Optional<RideGroup> findByUuid(String uuid);

    List<RideGroup> findByParentGroupUuid(String parentGroupUuid);

    Optional<RideGroup> findByRideAndParentGroupIsNull(Ride r);

    @Query("""
    SELECT g 
    FROM RideGroup g
    WHERE g.parentGroup.uuid = (
        SELECT mg.uuid 
        FROM RideGroup mg 
        WHERE mg.ride.uuid = :rideUuid 
        AND mg.parentGroup IS NULL
    )
    """)
    List<RideGroup> findSubGroupsByRideUuid(String rideUuid);
}
