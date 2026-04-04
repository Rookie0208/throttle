package com.ridersclub.ride.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.common.enums.Status;

@Repository
public interface RideParticipantRepository extends JpaRepository<RideParticipant, Long> {
    List<RideParticipant> findByRide_Id(Long rideId);
    List<RideParticipant> findByRide_IdAndRsvpStatusNot(Long rideId, Status status);

    boolean existsByRide_IdAndUser_Id(Long rideId, Long userId);
    boolean existsByRide_IdAndUser_IdAndRsvpStatusNot(Long rideId, Long userId, Status status);

    List<RideParticipant> findByUser_Id(Long userId);
    List<RideParticipant> findByUser_IdAndRsvpStatusNot(Long userId, Status status);

    long countByRide_Id(Long rideId);
    long countByRide_IdAndRsvpStatusNot(Long rideId, Status status);

    Optional<RideParticipant> findByRide_IdAndUser_Uuid(String rideId, String userUuid);
    Optional<RideParticipant> findByRide_UuidAndUser_Uuid(String rideUuid, String userUuid);
    Optional<RideParticipant> findByRide_UuidAndUser_UuidAndRsvpStatusNot(String rideUuid, String userUuid, Status status);
    List<Ride> findRidesByUserId(String userId);

    List<Ride> findRideByUser_Id(Long userId);

}
