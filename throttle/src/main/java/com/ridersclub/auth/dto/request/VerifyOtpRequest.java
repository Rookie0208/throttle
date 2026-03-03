package com.ridersclub.auth.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class VerifyOtpRequest {
    @NotBlank(message = "Email must not be blank")
    @Email(message = "Must be a valid email")
    private String email;

    @NotBlank(message = "OTP must not be blank")
    private String otp;
}
