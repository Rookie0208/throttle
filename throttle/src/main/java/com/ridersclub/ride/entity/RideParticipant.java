package com.ridersclub.ride.entity;

import java.time.LocalDateTime;

import com.ridersclub.user.entity.User;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "ride_participants")
@Getter
@Setter
public class RideParticipant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "ride_id")
    private Ride ride;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    private ParticipantRole role;

    @Enumerated(EnumType.STRING)
    private RsvpStatus rsvpStatus;

    private LocalDateTime joinedAt;

    public RideParticipant(Ride ride, User user) {
        this.ride = ride;
        this.user = user;
        this.role = ParticipantRole.ADMIN;
        this.rsvpStatus = RsvpStatus.PLANNED;  // creator joined
        this.joinedAt = LocalDateTime.now();
    }

    public RideParticipant(Object object, Long rideId, Long userId, LocalDateTime now) {
        //TODO Auto-generated constructor stub
    }
}
