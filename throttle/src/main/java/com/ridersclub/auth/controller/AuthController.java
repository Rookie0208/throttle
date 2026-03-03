package com.ridersclub.auth.controller;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.auth.dto.request.GoogleAuthRequest;
import com.ridersclub.auth.dto.request.GoogleRegisterRequest;
import com.ridersclub.auth.dto.request.VerifyOtpRequest;
import com.ridersclub.auth.dto.response.GoogleAuthResponse;
import com.ridersclub.auth.dto.request.LoginRequest;
import com.ridersclub.auth.dto.request.RegisterRequest;
import com.ridersclub.auth.dto.response.LoginResponse;
import com.ridersclub.auth.dto.response.RegisterResponse;
import com.ridersclub.auth.service.AuthService;
import com.ridersclub.common.dto.ApiResponse;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<RegisterResponse>> register(
            @Valid @RequestBody RegisterRequest request) {
        RegisterResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "User registered successfully"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success(response, "User logged in successfully"));
    }

    @PostMapping("/google/initiate")
    public ResponseEntity<ApiResponse<GoogleAuthResponse>> initiateGoogleAuth(
            @Valid @RequestBody GoogleAuthRequest request) {
        GoogleAuthResponse response = authService.verifyGoogleToken(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Google sign-in initiated"));
    }

    @PostMapping("/google/verify-otp")
    public ResponseEntity<ApiResponse<Boolean>> verifyOtp(
            @Valid @RequestBody VerifyOtpRequest request) {
        boolean isValid = authService.verifyOtp(request.getEmail(), request.getOtp());
        if (!isValid) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.failure(null, "Invalid or expired OTP"));
        }
        return ResponseEntity.ok(ApiResponse.success(true, "OTP verified successfully"));
    }

    @PostMapping("/google/complete-registration")
    public ResponseEntity<ApiResponse<LoginResponse>> completeGoogleRegistration(
            @Valid @RequestBody GoogleRegisterRequest request) {
        LoginResponse response = authService.completeGoogleRegistration(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "User registered and logged in successfully"));
    }

    // health-check endpoint can be kept if required
    @PostMapping("/test")
    public ResponseEntity<String> test() {
        return ResponseEntity.ok("Auth controller working");
    }
}
