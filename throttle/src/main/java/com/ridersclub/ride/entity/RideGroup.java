package com.ridersclub.ride.entity;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

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
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "ride_groups")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RideGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String uuid;

    // Ride reference
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ride_id", nullable = false)
    private Ride ride;

    // Parent group (for subgroups)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_group_id")
    private RideGroup parentGroup;

    @Column(nullable = false, length = 150)
    private String name;

    // Creator
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Members
    @OneToMany(mappedBy = "group", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<GroupMember> members = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Visibility visibility = Visibility.PUBLIC;

    @Column(name = "members_can_send_messages", nullable = false)
    private Boolean membersCanSendMessages = true;

    @Column(name = "members_can_add_members", nullable = false)
    private Boolean membersCanAddMembers = false;

    @Column(name = "admins_approve_members", nullable = false)
    private Boolean adminsApproveMembers = true;

    @Column(name = "pre_ride_meeting_point", length = 255)
    private String preRideMeetingPoint;

    @Column(name = "pre_ride_fuel_stops", length = 255)
    private String preRideFuelStops;

    @Column(name = "pre_ride_checkpoints", columnDefinition = "TEXT")
    private String preRideCheckpoints;

    @Column(name = "pre_ride_rules", columnDefinition = "TEXT")
    private String preRideRules;

    @Column(name = "pre_ride_notes", columnDefinition = "TEXT")
    private String preRideNotes;

    @Column(name = "pre_ride_updated_at")
    private LocalDateTime preRideUpdatedAt;

    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
