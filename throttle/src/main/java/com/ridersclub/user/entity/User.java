package com.ridersclub.user.entity;

import java.time.LocalDateTime;
import java.util.UUID;

import com.ridersclub.common.enums.Gender;
import com.ridersclub.common.enums.Role;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "users")
@Getter @Setter
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String firstName;
    private String lastName;
    private String uuid;
    @Column(unique = true, nullable = false)
    private String email;

    private String password;

    private String pronoun;

    private Gender gender;

    private String city;

    private String bikeType;

    @Enumerated(EnumType.STRING)
    private Role role = Role.RIDER;

    private boolean active = true;

    private LocalDateTime createdAt = LocalDateTime.now();

    private int experienceYears;

}
