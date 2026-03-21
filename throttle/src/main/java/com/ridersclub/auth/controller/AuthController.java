package com.ridersclub.auth.controller;

import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletRequest;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.auth.dto.request.GoogleAuthRequest;
import com.ridersclub.auth.dto.request.GoogleRegisterRequest;
import com.ridersclub.auth.dto.request.LoginRequest;
import com.ridersclub.auth.dto.request.LogoutRequest;
import com.ridersclub.auth.dto.request.RegisterRequest;
import com.ridersclub.auth.dto.request.TokenRefreshRequest;
import com.ridersclub.auth.dto.request.VerifyOtpRequest;
import com.ridersclub.auth.dto.response.GoogleAuthResponse;
import com.ridersclub.auth.dto.response.LoginResponse;
import com.ridersclub.auth.dto.response.RegisterResponse;
import com.ridersclub.auth.dto.response.TokenRefreshResponse;
import com.ridersclub.auth.security.JwtService;
import com.ridersclub.auth.service.AuthService;
import com.ridersclub.auth.service.RefreshTokenService;
import com.ridersclub.auth.service.TokenBlacklistService;
import com.ridersclub.common.Utils.ApiConstants;
import com.ridersclub.common.dto.ApiResponse;

@RestController
@RequestMapping(ApiConstants.Auth.BASE)
public class AuthController {

    private final AuthService authService;
    private final TokenBlacklistService tokenBlacklistService;
    private final RefreshTokenService refreshTokenService;
    private final JwtService jwtService;

    public AuthController(AuthService authService, 
                          TokenBlacklistService tokenBlacklistService,
                          RefreshTokenService refreshTokenService,
                          JwtService jwtService) {
        this.authService = authService;
        this.tokenBlacklistService = tokenBlacklistService;
        this.refreshTokenService = refreshTokenService;
        this.jwtService = jwtService;
    }

    @PostMapping(ApiConstants.Auth.REGISTER)
    public ResponseEntity<ApiResponse<RegisterResponse>> register(
            @Valid @RequestBody RegisterRequest request) {
        RegisterResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "User registered successfully"));
    }

    @PostMapping(ApiConstants.Auth.LOGIN)
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success(response, "User logged in successfully"));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Boolean>> logout(
            @Valid @RequestBody LogoutRequest logoutRequest,
            HttpServletRequest request) {
        
        String authHeader = request.getHeader("Authorization");
        String bearerToken = (authHeader != null && authHeader.startsWith("Bearer ")) ? authHeader.substring(7) : null;
        
        if (bearerToken != null) {
            try {
                java.util.Date expiration = jwtService.parse(bearerToken).getBody().getExpiration();
                long ttlMillis = expiration.getTime() - System.currentTimeMillis();
                tokenBlacklistService.blacklistToken(bearerToken, ttlMillis);
            } catch (Exception e) {
                // Ignore if token is already expired or invalid
            }
        }
        
        try {
            com.ridersclub.auth.entity.RefreshToken token = refreshTokenService.findByToken(logoutRequest.getRefreshToken())
                    .orElseThrow(() -> new RuntimeException("Refresh token not found"));
            refreshTokenService.deleteByToken(token);
        } catch (Exception e) {
            // Ignore if already deleted or doesn't exist
        }
        
        return ResponseEntity.ok(ApiResponse.success(true, "User logged out securely"));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<TokenRefreshResponse>> refreshToken(
            @Valid @RequestBody TokenRefreshRequest request) {
        
        String requestRefreshToken = request.getRefreshToken();
        
        return refreshTokenService.findByToken(requestRefreshToken)
                .map(refreshTokenService::verifyExpiration)
                .map(com.ridersclub.auth.entity.RefreshToken::getUser)
                .map(user -> {
                    // Refresh Token Rotation: Delete old one, create new one
                    refreshTokenService.deleteByToken(refreshTokenService.findByToken(requestRefreshToken).get());
                    com.ridersclub.auth.entity.RefreshToken newRefreshToken = refreshTokenService.createRefreshToken(user.getId());
                    
                    long expiresIn = 900L; // 15 mins
                    String roleValue = user.getRole() != null ? user.getRole().name() : "RIDER";
                    String newAccessToken = jwtService.generate(user.getUuid().toString(), java.util.Map.of("roles", roleValue), expiresIn);
                    
                    return ResponseEntity.ok(ApiResponse.success(
                            new TokenRefreshResponse(newAccessToken, newRefreshToken.getToken(), expiresIn),
                            "Token refreshed successfully"));
                })
                .orElseThrow(() -> new RuntimeException("Refresh token is not in database!"));
    }

    @PostMapping(ApiConstants.Auth.GOOGLE_INITIATE)
    public ResponseEntity<ApiResponse<GoogleAuthResponse>> initiateGoogleAuth(
            @Valid @RequestBody GoogleAuthRequest request) {
        GoogleAuthResponse response = authService.verifyGoogleToken(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Google sign-in initiated"));
    }

    @PostMapping(ApiConstants.Auth.GOOGLE_VERIFY_OTP)
    public ResponseEntity<ApiResponse<Boolean>> verifyOtp(
            @Valid @RequestBody VerifyOtpRequest request) {
        boolean isValid = authService.verifyOtp(request.getEmail(), request.getOtp());
        if (!isValid) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.failure(null, "Invalid or expired OTP"));
        }
        return ResponseEntity.ok(ApiResponse.success(true, "OTP verified successfully"));
    }

    @PostMapping(ApiConstants.Auth.GOOGLE_COMPLETE_REGISTRATION)
    public ResponseEntity<ApiResponse<LoginResponse>> completeGoogleRegistration(
            @Valid @RequestBody GoogleRegisterRequest request) {
        LoginResponse response = authService.completeGoogleRegistration(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "User registered and logged in successfully"));
    }

    // health-check endpoint can be kept if required
    @PostMapping(ApiConstants.Auth.TEST)
    public ResponseEntity<String> test() {
        return ResponseEntity.ok("Auth controller working");
    }
}
