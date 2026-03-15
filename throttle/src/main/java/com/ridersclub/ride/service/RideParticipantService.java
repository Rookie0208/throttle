package com.ridersclub.ride.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ridersclub.ride.entity.Ride;
import com.ridersclub.ride.entity.RideParticipant;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.dto.response.RideParticipantDto;

@Service
public class RideParticipantService {

    @Autowired
    private RideRepository rideRepository;
    @Autowired
    private RideParticipantRepository participantRepository;

    public List<RideParticipantDto> getRideParticipants(String rideId) {

    Ride ride = rideRepository.findByUuid(rideId)
            .orElseThrow(() -> new RuntimeException("Ride not found"));

    List<RideParticipant> participants = participantRepository.findByRide_Id(ride.getId());

    return participants.stream()
            .map(rp -> RideParticipantDto.builder()
                    .userUuid(rp.getUser().getUuid())
                    .firstName(rp.getUser().getFirstName())
                    .lastName(rp.getUser().getLastName())
                    .profileImage(rp.getUser().getProfileImage())
                    .role(rp.getRole().toString())
                    .rsvpStatus(rp.getRsvpStatus().toString())
                    .joinedAt(rp.getJoinedAt())
                    .build())
            .toList();
}

}
