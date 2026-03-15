package com.ridersclub.ride.entity;

import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.Status;
import com.ridersclub.user.entity.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
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

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ride_id", nullable = false)
    @JsonIgnore
    private Ride ride;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status rsvpStatus;

    @Column(nullable = false)
    private LocalDateTime joinedAt;

    public RideParticipant(Ride ride, User user) {
        this.ride = ride;
        this.user = user;
        this.role = Role.ADMIN;
        this.rsvpStatus = Status.CREATED;
        this.joinedAt = LocalDateTime.now();
    }

    // ✅ Generic participant constructor
    public RideParticipant(Ride ride, User user, Role role, Status status) {
        this.ride = ride;
        this.user = user;
        this.role = role;
        this.rsvpStatus = status;
        this.joinedAt = LocalDateTime.now();
    }
}