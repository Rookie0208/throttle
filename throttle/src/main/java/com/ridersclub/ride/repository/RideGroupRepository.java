package com.ridersclub.ride.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ridersclub.ride.entity.RideGroup;

public interface RideGroupRepository extends JpaRepository<RideGroup, String> {

}
