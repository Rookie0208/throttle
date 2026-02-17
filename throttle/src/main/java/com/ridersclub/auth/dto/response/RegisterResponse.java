package com.ridersclub.auth.dto.response;

import java.util.UUID;

public record RegisterResponse(String userId,
        boolean verificationRequired,
        String verificationType) {

}
