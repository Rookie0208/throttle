package com.ridersclub.ride.repository;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Ride;

@Repository
public interface RideRepository extends JpaRepository<Ride, Long> {
    Optional<Ride> findById(String id);

    public java.util.List<Ride> findAll();

    @Query("SELECT rp.ride FROM RideParticipant rp WHERE rp.user.uuid = :userUuid")
    List<Ride> findMyRides(@Param("userUuid") String userUuid);

    List<Ride> findByCreatedBy_Id(Long userId);
}
