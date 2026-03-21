package com.ridersclub.auth.dto.response;

import java.util.UUID;

public record LoginResponse(
                String userId,
                String token,
                String refreshToken,
                long expiresIn) {
}
