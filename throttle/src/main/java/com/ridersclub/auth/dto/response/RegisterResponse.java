package com.ridersclub.auth.dto.response;

import java.util.UUID;

public record RegisterResponse(UUID userId,
    boolean verificationRequired,
    String verificationType) {
         
}
