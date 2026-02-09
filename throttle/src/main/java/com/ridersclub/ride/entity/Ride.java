package com.ridersclub.ride.entity;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import com.ridersclub.common.enums.RouteType;
import com.ridersclub.common.enums.Visibility;

import jakarta.persistence.AttributeOverride;
import jakarta.persistence.AttributeOverrides;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Embedded;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "rides")
@Setter @Getter
public class Ride {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private UUID rideUid;

    @Column(nullable = false)
    private String title;

    @Column(length = 1000)
    private String description;

    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name = "name", column = @Column(name = "start_location_name")),
            @AttributeOverride(name = "latitude", column = @Column(name = "start_latitude")),
            @AttributeOverride(name = "longitude", column = @Column(name = "start_longitude"))
    })
    private RideLocation startLocation;

    @Embedded
    @AttributeOverrides({
            @AttributeOverride(name = "name", column = @Column(name = "end_location_name")),
            @AttributeOverride(name = "latitude", column = @Column(name = "end_latitude")),
            @AttributeOverride(name = "longitude", column = @Column(name = "end_longitude"))
    })
    private RideLocation endLocation;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RouteType routeType;

    @Column(nullable = false)
    private OffsetDateTime startTime;

    @Column(nullable = false)
    private Integer maxRiders;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Visibility visibility;

    @ElementCollection
    @CollectionTable(name = "ride_rules", joinColumns = @JoinColumn(name = "ride_id"))
    @Column(name = "rule", nullable = false)
    private List<String> rules;

    // OPTIONAL but recommended
    @Column(nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(nullable = false)
    private String createdBy;

    @PrePersist
    void onCreate() {
        this.createdAt = OffsetDateTime.now();
    }
}
