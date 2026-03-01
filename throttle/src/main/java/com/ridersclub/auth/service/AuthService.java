package com.ridersclub.auth.service;

import java.util.Map;
import java.util.UUID;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.ridersclub.auth.dto.request.LoginRequest;
import com.ridersclub.auth.dto.request.RegisterRequest;
import com.ridersclub.auth.dto.response.LoginResponse;
import com.ridersclub.auth.dto.response.RegisterResponse;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.Gender;
import com.ridersclub.common.exception.EmailAlreadyExistsException;
import com.ridersclub.common.exception.InvalidCredentialsException;
import com.ridersclub.common.exception.UserNotFoundException;
import com.ridersclub.auth.security.JwtService;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.service.UserService;

@Service
public class AuthService {

    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserService userService,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public LoginResponse login(LoginRequest request) {
        User user = userService.findByEmail(request.getEmail())
                .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new InvalidCredentialsException("Invalid email or password");
        }

        long expiresIn = 864_000L; // 10 days in seconds (example)
        // store simple role string; JwtAuthFilter will parse comma-separated list
        String roleValue = user.getRole() != null ? user.getRole().name() : "RIDER";
        String token = jwtService.generate(user.getUuid().toString(), Map.of("roles", roleValue), expiresIn);
        return new LoginResponse(user.getUuid().toString(), token, expiresIn);
    }

    public RegisterResponse register(RegisterRequest request) {
        if (userService.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyExistsException("Email already in use");
        }

        User user = new User();
        user.setUuid(UUID.randomUUID());
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setCity(request.getCity());
        user.setBikeType(request.getBikeType());
        user.setExperienceYears(request.getExperienceYears());
        user.setRole(request.getRole() != null ? request.getRole() : Role.RIDER);
        user.setPronoun(request.getPronoun());
        user.setGender(request.getGender() != null ? request.getGender() : com.ridersclub.common.enums.Gender.MALE);
        user.setActive(true);

        User saved = userService.save(user);
        boolean verificationRequired = true; // adjust logic as needed
        String verificationType = verificationRequired ? "EMAIL" : "NONE";
        return new RegisterResponse(saved.getUuid().toString(), verificationRequired, verificationType);
    }
}
