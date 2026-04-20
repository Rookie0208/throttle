package com.ridersclub.bike.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "bike_master", uniqueConstraints = {
        @UniqueConstraint(name = "uk_bike_master_brand_model_variant", columnNames = { "brand", "model", "variant" })
})
@Getter
@Setter
public class BikeMaster {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String brand;

    @Column(nullable = false, length = 100)
    private String model;

    @Column(nullable = false, length = 150)
    private String variant;

    @Column(name = "engine_cc")
    private Integer engineCc;

    @Column(length = 30)
    private String category;

    @Column(name = "bike_type", length = 100)
    private String bikeType;

    @Column(name = "tank_capacity", precision = 6, scale = 2)
    private BigDecimal tankCapacity;

    @Column(name = "range_km")
    private Integer rangeKm;

    @Column(name = "comfort_score")
    private Integer comfortScore;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "is_verified", nullable = false)
    private boolean verified = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
