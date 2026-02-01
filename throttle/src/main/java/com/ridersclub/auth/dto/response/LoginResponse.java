package com.ridersclub.auth.dto.response;

public record LoginResponse(
    String userId,
    String token,
    long expiresIn
) {}

