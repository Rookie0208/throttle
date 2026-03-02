package com.ridersclub.auth.dto.request;

import com.ridersclub.common.enums.Gender;
import com.ridersclub.common.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GoogleRegisterRequest {
    @NotBlank(message = "Email must not be blank")
    @Email(message = "Must be a valid email")
    private String email;

    @NotBlank(message = "First name is required")
    private String firstName;

    @NotBlank(message = "Last name is required")
    private String lastName;

    private String city;
    private String bikeType;
    private int experienceYears;
    private Role role;
    private String pronoun;
    private Gender gender;
}
