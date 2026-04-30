package com.ridersclub.user.dto.request;

import java.util.List;

import jakarta.validation.constraints.Size;
import jakarta.validation.Valid;
import lombok.Data;
import com.ridersclub.user.dto.common.EmergencyContactPayload;

@Data
public class UpdateProfileRequest {
    @Size(max = 50)
    private String firstName;

    @Size(max = 50)
    private String lastName;

    @Size(max = 500)
    private String bio;

    @Size(max = 255)
    private String profileImage;

    @Valid
    @Size(max = 3)
    private List<EmergencyContactPayload> emergencyContacts;

    @Size(max = 10)
    private String bloodGroup;

    @Size(max = 1000)
    private String allergies;

    @Size(max = 1000)
    private String currentMedication;
}
