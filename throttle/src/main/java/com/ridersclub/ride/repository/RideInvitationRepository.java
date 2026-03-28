package com.ridersclub.ride.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.common.enums.RideInvitationStatus;
import com.ridersclub.ride.entity.RideInvitation;

@Repository
public interface RideInvitationRepository extends JpaRepository<RideInvitation, Long> {
    boolean existsByRide_IdAndInvitee_IdAndStatus(Long rideId, Long inviteeId, RideInvitationStatus status);

    Optional<RideInvitation> findByIdAndInvitee_Uuid(Long id, String inviteeUuid);

    Optional<RideInvitation> findByIdAndInviter_Uuid(Long id, String inviterUuid);
}
