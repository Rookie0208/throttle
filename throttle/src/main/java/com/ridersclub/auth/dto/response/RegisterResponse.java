package com.ridersclub.auth.dto.response;

public record RegisterResponse(
        String userId,
        boolean verificationRequired,
        String verificationType,
        String token,
        String refreshToken,
        Long expiresIn) {

}
