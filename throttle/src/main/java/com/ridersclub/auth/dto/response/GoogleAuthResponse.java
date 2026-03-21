package com.ridersclub.auth.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class GoogleAuthResponse {
    private boolean requiresRegistration;
    private boolean otpSent;
    private String email;
    private String firstName;
    private String lastName;
    private String token; // JWT if login is successful
    private String refreshToken;
    private Long expiresIn;
}
