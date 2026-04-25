package com.ridersclub.auth.service;

import java.util.Collections;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;

import com.ridersclub.auth.dto.request.GoogleAuthRequest;
import com.ridersclub.auth.dto.request.GoogleRegisterRequest;
import com.ridersclub.auth.dto.response.GoogleAuthResponse;
import com.ridersclub.auth.dto.request.LoginRequest;
import com.ridersclub.auth.dto.request.RegisterRequest;
import com.ridersclub.auth.dto.response.LoginResponse;
import com.ridersclub.auth.dto.response.RegisterResponse;
import com.ridersclub.common.Utils.NormalizeUtil;
import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.UuidPrefix;
import com.ridersclub.common.exception.EmailAlreadyExistsException;
import com.ridersclub.common.exception.InvalidCredentialsException;
import com.ridersclub.auth.security.JwtService;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.service.RiderIdService;
import com.ridersclub.user.service.UserService;

@Slf4j
@Service
public class AuthService {

    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final OtpService otpService;
    private final RefreshTokenService refreshTokenService;
    private final org.springframework.data.neo4j.core.Neo4jClient neo4jClient;
    private final RiderIdService riderIdService;

    @Value("${google.client.id}")
    private String googleClientId;

    @Value("${google.auth.require-otp:false}")
    private boolean requireOtp;

    public AuthService(UserService userService,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            OtpService otpService,
            RefreshTokenService refreshTokenService,
            org.springframework.data.neo4j.core.Neo4jClient neo4jClient,
            RiderIdService riderIdService) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.otpService = otpService;
        this.refreshTokenService = refreshTokenService;
        this.neo4jClient = neo4jClient;
        this.riderIdService = riderIdService;
    }

    /** Async Neo4j dual-write — MERGE so it's safe to call multiple times */
    private void syncUserToNeo4j(String uuid, String firstName, String lastName) {
        java.util.concurrent.CompletableFuture.runAsync(() -> {
            try {
                neo4jClient.query(
                        "MERGE (u:User {id: $id}) " +
                                "SET u.firstName = $firstName, u.lastName = $lastName")
                        .bind(uuid).to("id")
                        .bind(firstName != null ? firstName : "").to("firstName")
                        .bind(lastName != null ? lastName : "").to("lastName")
                        .run();
                log.info("Neo4j node created/updated for user {}", uuid);
            } catch (Exception e) {
                log.error("Failed to sync user {} to Neo4j: {}", uuid, e.getMessage());
            }
        });
    }

    public LoginResponse login(LoginRequest request) {
        String email = NormalizeUtil.lowerTrim(request.getEmail());
        User user = userService.findByEmail(email)
                .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password"));

        if (user.getPassword() == null || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new InvalidCredentialsException("Invalid email or password");
        }

        if (!user.isActive()) {
            throw new InvalidCredentialsException("Account is blocked. Please contact support.");
        }

        if (request.getRole() != null && !request.getRole().trim().isEmpty()) {
             if (user.getRole() == null || !user.getRole().name().equalsIgnoreCase(request.getRole())) {
                 throw new InvalidCredentialsException("No account found matching these credentials with the selected role.");
             }
        }

        long expiresIn = 900L; // 15 mins Access Token TTL
        // store simple role string; JwtAuthFilter will parse comma-separated list
        String roleValue = user.getRole() != null ? user.getRole().name() : "RIDER";
        String token = jwtService.generate(user.getUuid().toString(), Map.of("roles", roleValue), expiresIn);

        String refreshToken = refreshTokenService.createRefreshToken(user.getId()).getToken();
        return new LoginResponse(user.getUuid().toString(), token, refreshToken, expiresIn);
    }

    public RegisterResponse register(RegisterRequest request) {
        if (userService.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyExistsException("Email already in use");
        }
        String normalizedRiderId = riderIdService.normalizeAndValidateRequested(request.getRiderId());
        riderIdService.assertAvailable(normalizedRiderId);

        User user = new User();
        user.setUuid(UserUtility.generateUUID(UuidPrefix.USER.name()));
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setRiderId(normalizedRiderId);
        user.setEmail(request.getEmail());
        user.setUsername(request.getUsername() != null ? request.getUsername()
                : (request.getFirstName() + " " + request.getLastName()).trim());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setCity(request.getCity());
        user.setBikeType(request.getBikeType());
        user.setExperienceYears(request.getExperienceYears());
        user.setRole(request.getRole() != null ? request.getRole() : Role.RIDER);
        user.setPronoun(request.getPronoun());
        user.setGender(request.getGender() != null ? request.getGender() : com.ridersclub.common.enums.Gender.MALE);
        user.setActive(true);

        User saved = userService.save(user);
        syncUserToNeo4j(saved.getUuid(), saved.getFirstName(), saved.getLastName());

        boolean verificationRequired = true;
        String verificationType = verificationRequired ? "EMAIL" : "NONE";

        long expiresIn = 900L;
        String roleValue = saved.getRole() != null ? saved.getRole().name() : "RIDER";
        String token = jwtService.generate(saved.getUuid().toString(), Map.of("roles", roleValue), expiresIn);
        String refreshToken = refreshTokenService.createRefreshToken(saved.getId()).getToken();

        return new RegisterResponse(saved.getUuid().toString(), verificationRequired, verificationType, token,
                refreshToken, expiresIn);
    }

    public GoogleAuthResponse verifyGoogleToken(GoogleAuthRequest request) {
        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(),
                    new GsonFactory())
                    .setAudience(Collections.singletonList(googleClientId))
                    .build();

            GoogleIdToken idToken = verifier.verify(request.getIdToken());
            if (idToken != null) {
                GoogleIdToken.Payload payload = idToken.getPayload();
                String email = payload.getEmail();
                String firstName = (String) payload.get("given_name");
                String lastName = (String) payload.get("family_name");

                var userOpt = userService.findByEmail(email);
                if (userOpt.isPresent()) {
                    // User exists, just log them in (return JWT)
                    log.info("Existing user logged in via Google: {}", email);
                    User user = userOpt.get();
                    long expiresIn = 900L;
                    String roleValue = user.getRole() != null ? user.getRole().name() : "RIDER";
                    String token = jwtService.generate(user.getUuid().toString(), Map.of("roles", roleValue),
                            expiresIn);
                    String refreshToken = refreshTokenService.createRefreshToken(user.getId()).getToken();
                    return new GoogleAuthResponse(false, false, email, firstName, lastName, token, refreshToken,
                            expiresIn);
                } else {
                    // New User -> Check if OTP is required by config
                    if (requireOtp) {
                        log.info("New user initiated Google sign-in. Sending OTP to: {}", email);
                        otpService.generateAndSendOtp(email);
                        return new GoogleAuthResponse(true, true, email, firstName, lastName, null, null, null);
                    } else {
                        log.info("New user initiated Google sign-in. OTP disabled. Proceeding to profile setup: {}",
                                email);
                        return new GoogleAuthResponse(true, false, email, firstName, lastName, null, null, null);
                    }
                }
            } else {
                throw new InvalidCredentialsException("Invalid Google ID token.");
            }
        } catch (Exception e) {
            throw new InvalidCredentialsException("Google authentication failed: " + e.getMessage());
        }
    }

    public LoginResponse completeGoogleRegistration(GoogleRegisterRequest request) {
        if (userService.existsByEmail(request.getEmail())) {
            log.warn("Attempted to complete Google registration for existing email: {}", request.getEmail());
            throw new EmailAlreadyExistsException("Email already in use");
        }
        String normalizedRiderId = riderIdService.normalizeAndValidateRequested(request.getRiderId());
        riderIdService.assertAvailable(normalizedRiderId);

        User user = new User();
        user.setUuid(UserUtility.generateUUID(UuidPrefix.USER.name()));
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setRiderId(normalizedRiderId);
        user.setEmail(request.getEmail());
        user.setUsername(request.getRiderId());
        user.setPassword(passwordEncoder.encode(UUID.randomUUID().toString())); // Dummy password for OAuth users to
                                                                                // satisfy DB constraint
        user.setCity(request.getCity());
        user.setBikeType(request.getBikeType());
        user.setExperienceYears(request.getExperienceYears());
        user.setRole(request.getRole() != null ? request.getRole() : Role.RIDER);
        user.setPronoun(request.getPronoun());
        user.setGender(request.getGender() != null ? request.getGender() : com.ridersclub.common.enums.Gender.MALE);
        user.setActive(true);

        User saved = userService.save(user);
        syncUserToNeo4j(saved.getUuid(), saved.getFirstName(), saved.getLastName());
        log.info("Completed Google registration for new user: {}", request.getEmail());

        long expiresIn = 900L;
        String roleValue = saved.getRole() != null ? saved.getRole().name() : "RIDER";
        String token = jwtService.generate(saved.getUuid().toString(), Map.of("roles", roleValue), expiresIn);
        String refreshToken = refreshTokenService.createRefreshToken(saved.getId()).getToken();
        return new LoginResponse(saved.getUuid().toString(), token, refreshToken, expiresIn);
    }

    public boolean verifyOtp(String email, String otp) {
        return otpService.verifyOtp(email, otp);
    }
}
