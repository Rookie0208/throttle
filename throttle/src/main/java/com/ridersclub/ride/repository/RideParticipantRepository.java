package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideParticipant;

@Repository
public interface RideParticipantRepository extends JpaRepository<RideParticipant, Long> {
    List<RideParticipant> findByRide_Id(String rideId);

    boolean existsByRide_IdAndUser_Id(Long rideId, Long userId);

    List<RideParticipant> findByUser_Id(String userId);

    long countByRide_Id(Long rideId);

    Optional<RideParticipant> findByRide_IdAndUser_Uuid(
        String rideId,
        String userUuid
);
    List<Ride> findRidesByUserId(String userId);

}