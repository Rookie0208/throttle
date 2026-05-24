package com.ridersclub.admin.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "system_resources")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SystemResource {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "resource_key", unique = true, nullable = false, length = 100)
    private String resourceKey;

    @Column(name = "resource_value", nullable = false, columnDefinition = "TEXT")
    private String resourceValue;

    @Column(name = "resource_type", nullable = false, length = 30)
    private String resourceType; // STRING, BOOLEAN, NUMBER, SECRET, JSON

    @Column(name = "category", nullable = false, length = 50)
    private String category; // FEATURE_FLAGS, API_KEYS, SYSTEM_RATES, OTHER

    @Column(name = "description", length = 255)
    private String description;

    @Builder.Default
    @Column(name = "is_secret", nullable = false)
    private Boolean isSecret = false;

    @Builder.Default
    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Builder.Default
    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "updated_by", length = 100)
    private String updatedBy;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (isSecret == null) {
            isSecret = false;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
