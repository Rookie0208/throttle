package com.ridersclub.auth.dto.response;

public record TokenRefreshResponse(
    String accessToken,
    String refreshToken,
    long expiresIn
) {}
