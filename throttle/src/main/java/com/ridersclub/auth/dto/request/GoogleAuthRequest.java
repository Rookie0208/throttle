package com.ridersclub.auth.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GoogleAuthRequest {
    @NotBlank(message = "Google ID token must not be blank")
    private String idToken;
}
