package com.ridersclub.auth.dto.response;

public record RegisterResponse(String userId,
    boolean verificationRequired,
    String verificationType) {

}
