package com.ridersclub.auth.dto.request;

import java.util.List;

import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.Gender;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank
    @Size(max = 50)
    private String firstName;

    @NotBlank
    @Size(max = 50)
    private String lastName;

    private Gender gender;

    @NotBlank
    @Size(max = 20)
    private String pronoun;

    @NotBlank
    @Email
    private String email;

    @Size(max = 50)
    private String username;

    @NotBlank
    @Size(min = 3, max = 30)
    @Pattern(regexp = "^[A-Za-z0-9._]+$", message = "Rider ID can only contain letters, numbers, dots, and underscores")
    private String riderId;

    @NotBlank
    @Size(min = 6, max = 100)
    private String password;

    @Size(max = 100)
    private String city;

    private int experienceYears;
    private List<Integer> emergencyContacts;

    @Size(max = 100)
    private String bikeType;

    private Long bikeMasterId;

    @Size(max = 80)
    private String bikeBrand;

    @Size(max = 80)
    private String bikeModel;

    @Size(max = 150)
    private String bikeVariant;

    @Size(max = 50)
    private String bikeCategory;

    private Integer bikeYear;

    private Integer bikeEngineCc;

    private Role role;
}
