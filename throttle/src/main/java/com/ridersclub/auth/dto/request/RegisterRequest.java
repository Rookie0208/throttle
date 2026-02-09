package com.ridersclub.auth.dto.request;

import java.util.List;

import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.Gender;

import lombok.Data;

@Data
public class RegisterRequest {
    private String firstName;
    private String lastName;
    private Gender gender;
    private String pronoun;
    private String email;
    private String password;
    private String city;
    private int experienceYears;
    private List<Integer> emergencyContacts;
    private String bikeType;
    private Role role;
}
