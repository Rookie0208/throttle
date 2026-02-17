package com.ridersclub.auth.dto.response;

import java.util.UUID;

public record LoginResponse(
        UUID userId,
        String token,
        long expiresIn) {
}
