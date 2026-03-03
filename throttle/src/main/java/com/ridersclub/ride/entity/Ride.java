package com.ridersclub.ride.entity;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

import com.ridersclub.common.enums.RideType;
import com.ridersclub.common.enums.RouteType;
import com.ridersclub.common.enums.Status;
import com.ridersclub.common.enums.Visibility;
import com.ridersclub.user.entity.User;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "rides")
@Getter
@Setter
public class Ride {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String uuid;

    @ManyToOne
    @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;

    @Column(nullable = false, length = 150)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RideType rideType;   // SOLO / GROUP

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RouteType routeType;   // ROAD / MOUNTAIN / HYBRID

    @Column(columnDefinition = "TEXT")
    private String description;

    @OneToMany(
        mappedBy = "ride",
        cascade = CascadeType.ALL,
        orphanRemoval = true
    )
    @OrderBy("ruleOrder ASC")
    private List<RideRule> rules = new ArrayList<>();

    @Column(nullable = false)
    private LocalDateTime startTime;

    private LocalDateTime endTime;

    @Column(nullable = false)
    private String startLocation;

    @Column(nullable = false)
    private String endLocation;

    @Column(nullable = false)
    private Double startLat;

    @Column(nullable = false)
    private Double startLng;

    @Column(nullable = false)
    private Double endLat;

    @Column(nullable = false)
    private Double endLng;

    private Integer maxRiders;

    @ManyToOne
    @JoinColumn(name = "captain_id")
    private User captain;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Visibility visibility;   // PUBLIC / PRIVATE

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;   // UPCOMING / COMPLETED / CANCELLED

    @Column(nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    public void onCreate() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }
}