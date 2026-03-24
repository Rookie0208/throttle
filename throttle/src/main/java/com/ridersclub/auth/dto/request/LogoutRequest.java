package com.ridersclub.auth.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Data
public class LogoutRequest {
    @NotBlank
    private String refreshToken;
}
