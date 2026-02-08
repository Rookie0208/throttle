package com.ridersclub.ride.repository;
import org.springframework.stereotype.Repository;

import com.ridersclub.ride.entity.Ride;

@Repository
public interface RideRepository extends org.springframework.data.repository.Repository<Ride, Long> {

    public Ride save(Ride ride);

    public java.util.List<Ride> findAll();

}
