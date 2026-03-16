package com.ridersclub.ride.service;

import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.ride.dto.request.AssignRoleRequest;
import com.ridersclub.ride.dto.request.RemoveRiderRequest;
import com.ridersclub.ride.entity.Ride;
// import com.ridersclub.ride.entity.RideMember;
// import com.ridersclub.ride.enums.RideRole;
// import com.ridersclub.ride.repository.RideMemberRepository;
import com.ridersclub.ride.repository.RideRepository;

@Service
public class RideCaptainService {

    // @Rohan: check this serivce

    // private final RideRepository rideRepository;
    // private final RideMemberRepository rideMemberRepository;

    // public RideCaptainService(
    //         RideRepository rideRepository,
    //         RideMemberRepository rideMemberRepository) {
    //     this.rideRepository = rideRepository;
    //     this.rideMemberRepository = rideMemberRepository;
    // }

    // /**
    //  * Assign role to a rider
    //  */
    // @Transactional
    // public void assignRole(String rideUuid, AssignRoleRequest request) {

    //     // 1️⃣ Validate ride
    //     Ride ride = rideRepository.findByUuid(rideUuid)
    //             .orElseThrow(() -> new RuntimeException("Ride not found"));

    //     // 2️⃣ Validate rider in ride
    //     RideMember member = rideMemberRepository
    //             .findByRideUuidAndUserUuid(rideUuid, request.getUserUuid())
    //             .orElseThrow(() -> new RuntimeException("Rider not part of this ride"));

    //     // 3️⃣ Validate role
    //     RideRole role;
    //     try {
    //         role = RideRole.valueOf(request.getRole());
    //     } catch (IllegalArgumentException e) {
    //         throw new RuntimeException("Invalid role: " + request.getRole());
    //     }

    //     // 4️⃣ Assign role
    //     member.setRole(role);

    //     rideMemberRepository.save(member);
    // }

    // /**
    //  * Remove rider from ride
    //  */
    // @Transactional
    // public void removeRider(String rideUuid, RemoveRiderRequest request) {

    //     // 1️⃣ Validate ride
    //     Ride ride = rideRepository.findByUuid(rideUuid)
    //             .orElseThrow(() -> new RuntimeException("Ride not found"));

    //     // 2️⃣ Find member
    //     RideMember member = rideMemberRepository
    //             .findByRideUuidAndUserUuid(rideUuid, request.getUserUuid())
    //             .orElseThrow(() -> new RuntimeException("Rider not part of this ride"));

    //     // 3️⃣ Prevent removing captain
    //     if (member.getRole() == RideRole.CAPTAIN) {
    //         throw new RuntimeException("Captain cannot be removed from ride");
    //     }

    //     // 4️⃣ Delete member
    //     rideMemberRepository.delete(member);
    // }
}