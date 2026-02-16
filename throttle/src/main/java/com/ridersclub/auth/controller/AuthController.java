package com.ridersclub.auth.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.auth.dto.request.LoginRequest;
import com.ridersclub.auth.dto.request.RegisterRequest;
import com.ridersclub.auth.dto.response.LoginResponse;
import com.ridersclub.auth.dto.response.RegisterResponse;
import com.ridersclub.auth.security.JwtService;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.service.UserService;

@CrossOrigin(origins = "http://localhost:61215/")
@RestController
@RequestMapping("api/v1/auth")
public class AuthController {

    @Autowired
    private JwtService jwtService;

    @Autowired
    private UserService userService;

    @PostMapping("/register")
    ResponseEntity<ApiResponse<RegisterResponse>> register(@RequestBody RegisterRequest request) {
        User user = userService.register(request);

        System.out.println("Encoded Password: " + user.getPassword());
        RegisterResponse response = new RegisterResponse(user.getUuid().toString(), false, "none");
        System.out.println("Received registration request: " + request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "User registered successfully"));
    }

    @PostMapping("/login")
    ResponseEntity<ApiResponse<LoginResponse>> login(@RequestBody LoginRequest request) {
        User user = userService.authenticate(request);
        String token = jwtService.generate(user.getUuid().toString(), Map.of("roles", user.getRole()), 864000);

        LoginResponse response = new LoginResponse(user.getUuid().toString(), token, 864000);
        return ResponseEntity.ok(ApiResponse.success(response, "User logged in successfully"));
    }

    @GetMapping("/test")
    public String test() {
        return "Auth controller working";
    }

}
