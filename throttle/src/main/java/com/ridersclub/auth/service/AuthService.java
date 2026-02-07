package com.ridersclub.auth.service;

import java.time.LocalDateTime;
import org.springframework.security.authentication.BadCredentialsException;
import com.ridersclub.auth.dto.request.LoginRequest;
import com.ridersclub.auth.dto.request.RegisterRequest;
import com.ridersclub.auth.dto.response.LoginResponse;
import com.ridersclub.auth.dto.response.RegisterResponse;
import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.Role;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

public class AuthService {
 private final UserRepository userRepository;
 
 public AuthService(UserRepository userRepository) {
   this.userRepository = userRepository;
 }

 public LoginResponse login(LoginRequest request) {
    User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

    if(user == null) {
      user = new User();
      user.setId((long) 1);
      user.setUuid(UserUtility.generateUserId("USER"));
      user.setEmail(request.getEmail());
    }
    return new LoginResponse(user.getUuid(), "token-placeholder", 3600L);
 }

    public RegisterResponse register(RegisterRequest request) {
        if (request != null && userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already in use");
        }

        User newUser = new User();
        newUser.setUuid(UserUtility.generateUserId("USER"));
        newUser.setEmail("amitsr2612@gmail.com");
        newUser.setPassword("password");
        newUser.setCreatedAt(LocalDateTime.now());
        newUser.setBikeType("naked");
        newUser.setCity("Delhi");
        newUser.setFirstName("Amit");
        newUser.setLastName("Rawat");
        newUser.setRole(Role.ADMIN);
        newUser.setActive(true);
        // Set other fields from request as needed

        // Save user to repository (not implemented here)
        userRepository.save(newUser);
        boolean verificationRequired = true; // Assume verification is required

        return new RegisterResponse(newUser.getUuid(), verificationRequired, verificationRequired ? "EMAIL" : "NONE");
    }
}
