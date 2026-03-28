package com.ridersclub.auth.dto.request;

import com.ridersclub.common.enums.Gender;
import com.ridersclub.common.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
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

    @NotBlank(message = "Rider ID is required")
    @Size(min = 3, max = 30, message = "Rider ID must be between 3 and 30 characters")
    @Pattern(regexp = "^[A-Za-z0-9._]+$", message = "Rider ID can only contain letters, numbers, dots, and underscores")
    private String riderId;

    private String city;
    private String bikeType;
    private int experienceYears;
    private Role role;

    @NotBlank(message = "Pronoun is required")
    @Size(max = 20, message = "Pronoun must be 20 characters or fewer")
    private String pronoun;

    private Gender gender;
}
