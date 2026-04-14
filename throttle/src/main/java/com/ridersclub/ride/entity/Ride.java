package com.ridersclub.ride.entity;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

import com.ridersclub.common.Utils.NormalizeUtil;
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
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "rides")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Ride {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String uuid;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;

    // Club reference
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id")
    private Club club;

    @Column(nullable = false, length = 150)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RideType rideType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RouteType routeType;

    @Column(columnDefinition = "TEXT")
    private String description;

    // Ride Rules
    @OneToMany(mappedBy = "ride", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("ruleOrder ASC")
    private List<RideRule> rules = new ArrayList<>();

    @Column(nullable = false)
    private LocalDateTime startTime;

    private LocalDateTime endTime;

    private LocalDateTime rideStartedAt;

    private LocalDateTime rideCompletedAt;

    private Integer currentCheckpointIndex;

    @Column(columnDefinition = "TEXT")
    private String latestBroadcastMessage;

    private LocalDateTime latestBroadcastAt;

    @Column(columnDefinition = "TEXT")
    private String activeSosMessage;

    private LocalDateTime activeSosAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "active_sos_user_id")
    private User activeSosRaisedBy;

    private LocalDateTime activeSosResolvedAt;

    @Column(length = 32)
    private String activeSosResolution;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "active_sos_resolved_by_user_id")
    private User activeSosResolvedBy;

    // Ride Locations (START / CHECKPOINT / END)
    @OneToMany(mappedBy = "ride", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sequence ASC")
    private List<RideLocation> locations = new ArrayList<>();

    private Integer maxRiders;

    @OneToMany(mappedBy = "ride", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RideGroup> groups = new ArrayList<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "captain_id")
    private User captain;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Visibility visibility;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;

    @Column(nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(nullable = false)
    private OffsetDateTime updatedAt;

    public void addLocation(RideLocation location) {
        locations.add(location);
        location.setRide(this);
    }

    @PrePersist
    public void beforeSave() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();

        // normalize
        title = NormalizeUtil.trim(title);
    }

    @PreUpdate
    public void beforeUpdate() {
        this.updatedAt = OffsetDateTime.now();

        // normalize
        title = NormalizeUtil.trim(title);
    }
}
