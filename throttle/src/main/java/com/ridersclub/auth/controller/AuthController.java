package com.ridersclub.auth.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
import com.ridersclub.common.dto.ApiResponse;

@CrossOrigin(origins = "http://127.0.0.1:5500")
@RestController
@RequestMapping("api/v1/auth")
public class AuthController {

    @GetMapping("/register")
    ResponseEntity<ApiResponse<RegisterResponse>> register() {
        // RegisterRequest request = new RegisterRequest();
        // request.setFirstName("amit");
        // request.setLastName("rawat");
        // request.setEmail("amitsr2612@gmail.com");
        // request.setPassword("password");
        // request.setCity("delhi");
        // request.setExperienceYears(5);

        RegisterResponse response = new RegisterResponse("userId12345", false, "none");
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "User registered successfully"));
    }

    @PostMapping("/register")
    ResponseEntity<ApiResponse<RegisterResponse>> register(@RequestBody RegisterRequest request) {
        RegisterResponse response = new RegisterResponse("THIS_IS_USER_ID", false, "none");
        System.out.println("Received registration request: " + request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "User registered successfully"));
    }

    @PostMapping("/login")
    ResponseEntity<ApiResponse<LoginResponse>> login(@RequestBody LoginRequest request) {
        LoginRequest r = new LoginRequest();
        r.setEmail("amitsr2612@gmail.com");
        r.setPassword("password");

        if(request.getEmail().equals(r.getEmail()) && request.getPassword().equals(r.getPassword())) {
            System.out.println("Login successful for email: " + request.getEmail());
        } else {
            System.out.println("Login failed for email: " + request.getEmail());
        }
        LoginResponse response = new LoginResponse("THIS_IS_USER_ID", "dummy-jwt-token", 3600);
        return ResponseEntity.ok(ApiResponse.success(response, "User logged in successfully"));
    }

    @GetMapping("/test")
    public String test() {
        return "Auth controller working";
    }

}
