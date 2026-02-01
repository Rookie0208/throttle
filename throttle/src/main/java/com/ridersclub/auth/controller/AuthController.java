package com.ridersclub.auth.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;

import com.ridersclub.auth.dto.request.RegisterRequest;
import com.ridersclub.auth.dto.response.RegisterResponse;
import com.ridersclub.common.dto.ApiResponse;

@Controller
@RequestMapping("/auth")
public class AuthController {

    @PostMapping("/register")
    ResponseEntity<ApiResponse<RegisterResponse>> register(@RequestBody RegisterRequest request) {
        RegisterResponse response = new RegisterResponse("userId", false, "none");
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(response, "User registered successfully"));
    }
}
