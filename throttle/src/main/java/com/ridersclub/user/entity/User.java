package com.ridersclub.user.entity;

import java.util.ArrayList;
import java.util.List;

import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import com.ridersclub.common.Utils.NormalizeUtil;
import com.ridersclub.common.enums.Gender;
import com.ridersclub.common.enums.Role;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import com.ridersclub.user.dto.common.EmergencyContactPayload;

@Entity
@Table(name = "users")
@Getter
@Setter
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String firstName;
    private String lastName;

    @Column(nullable = false, unique = true, updatable = false, length = 100)
    private String uuid;

    @Column(unique = true, nullable = false, updatable = false, length = 30)
    private String riderId;

    @Column(unique = true, nullable = false)
    private String username;
    @Column(unique = true, nullable = false)
    private String email;

    private String password;

    private String pronoun;

    @Enumerated(EnumType.STRING)
    private Gender gender;

    private String city;

    private String bio;

    private String profileImage;

    private String bikeType;

    private boolean subscriptionActive = false;

    @Enumerated(EnumType.STRING)
    private Role role = Role.RIDER;

    private boolean active = true;

    private LocalDateTime createdAt = LocalDateTime.now();

    private int experienceYears;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private List<EmergencyContactPayload> emergencyContacts = new ArrayList<>();

    @Column(length = 10)
    private String bloodGroup;

    @Column(length = 1000)
    private String allergies;

    @Column(length = 1000)
    private String currentMedication;

    public boolean hasRole(String string) {
        return role.name().equals(string);
    }

    @PrePersist
    @PreUpdate
    public void normalize() {
        username = NormalizeUtil.capitalizeTrim(username);
        email = NormalizeUtil.lowerTrim(email);
        city = NormalizeUtil.lowerTrim(city);
        firstName = NormalizeUtil.capitalizeTrim(firstName);
        lastName = NormalizeUtil.capitalizeTrim(lastName);
        pronoun = NormalizeUtil.trim(pronoun);

    }

}
