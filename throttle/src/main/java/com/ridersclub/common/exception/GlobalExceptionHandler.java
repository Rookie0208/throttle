package com.ridersclub.common.exception;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.ridersclub.common.dto.ApiErrors;
import com.ridersclub.common.dto.ApiResponse;

import jakarta.servlet.http.HttpServletRequest;

@RestControllerAdvice
public class GlobalExceptionHandler {
@ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ApiResponse<Void>> badRequest(MethodArgumentNotValidException ex, HttpServletRequest request) {
    ApiErrors error = new ApiErrors("VALIDATION_FAILED", ex.getMessage(), request.getRequestURI());
    return ResponseEntity.badRequest().body(ApiResponse.failure(error, "Validation failed"));
  }

  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ApiResponse<Void>> illegalArg(IllegalArgumentException ex, HttpServletRequest request) {
    ApiErrors error = new ApiErrors("BAD_REQUEST", ex.getMessage(), request.getRequestURI());
    return ResponseEntity.badRequest().body(ApiResponse.failure(error, "Invalid argument provided"));
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiResponse<Void>> generic(Exception ex, HttpServletRequest request) {
    ApiErrors error = new ApiErrors("INTERNAL_SERVER_ERROR", ex.getMessage(), request.getRequestURI());
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiResponse.failure(error, "An unexpected error occurred"));
  }

  @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiResponse<Void>> handleBadCredentials(BadCredentialsException ex, HttpServletRequest request) {
        ApiErrors error = new ApiErrors("AUTH_INVALID_CREDENTIALS",ex.getMessage(),request.getRequestURI());

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.failure(error, "Login failed"));
    }
}
