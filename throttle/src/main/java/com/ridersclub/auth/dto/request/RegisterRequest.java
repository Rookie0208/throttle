package com.ridersclub.auth.dto.request;

import java.util.List;

import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.Gender;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
    private String pronoun;

    @NotBlank
    @Email
    private String email;

    @Size(max = 50)
    private String username;

    @NotBlank
    @Size(min = 6, max = 100)
    private String password;

    @Size(max = 100)
    private String city;

    private int experienceYears;
    private List<Integer> emergencyContacts;

    @Size(max = 100)
    private String bikeType;

    private Role role;
}
