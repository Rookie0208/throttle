package com.ridersclub.ride.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Column;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "ride_stats")
@Data
@AllArgsConstructor
@NoArgsConstructor
public class RideStats {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "ride_id")
    private String rideId;

    @Column(name = "user_id")
    private String userId;

    @Column(name = "distance_km")
    private double distanceKm;

    @Column(name = "duration_minutes")
    private long durationMinutes;

    @Column(name = "avg_speed")
    private double avgSpeed;
}
