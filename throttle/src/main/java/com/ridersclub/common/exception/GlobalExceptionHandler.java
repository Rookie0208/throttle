package com.ridersclub.common.exception;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.ridersclub.common.dto.ApiErrors;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.common.exception.EmailAlreadyExistsException;
import com.ridersclub.common.exception.InvalidCredentialsException;
import com.ridersclub.common.exception.RiderIdAlreadyExistsException;
import com.ridersclub.common.exception.UserNotFoundException;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;

@Slf4j
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
    log.error("Invalid argument: ", ex);
    return ResponseEntity.badRequest().body(ApiResponse.failure(error, "Invalid argument provided"));
  }

  @ExceptionHandler(RuntimeException.class)
  public ResponseEntity<ApiResponse<Void>> runtime(RuntimeException ex, HttpServletRequest request) {
    ApiErrors error = new ApiErrors("RUNTIME_ERROR", ex.getMessage(), request.getRequestURI());
    log.error("Runtime exception on {}", request.getRequestURI(), ex);
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiResponse.failure(error, "A runtime error occurred"));
  }

  @ExceptionHandler(SecurityException.class)
  public ResponseEntity<ApiResponse<Void>> security(SecurityException ex, HttpServletRequest request) {
    ApiErrors error = new ApiErrors("FORBIDDEN", ex.getMessage(), request.getRequestURI());
    log.warn("Security exception on {}: {}", request.getRequestURI(), ex.getMessage());
    return ResponseEntity.status(HttpStatus.FORBIDDEN)
        .body(ApiResponse.failure(error, "You are not allowed to perform this action"));
  }

  @ExceptionHandler(AccessDeniedException.class)
  public ResponseEntity<ApiResponse<Void>> accessDenied(AccessDeniedException ex, HttpServletRequest request) {
    ApiErrors error = new ApiErrors("ACCESS_DENIED", ex.getMessage(), request.getRequestURI());
    log.warn("Access denied on {}: {}", request.getRequestURI(), ex.getMessage());
    return ResponseEntity.status(HttpStatus.FORBIDDEN)
        .body(ApiResponse.failure(error, "You do not have permission to access this resource"));
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiResponse<Void>> generic(Exception ex, HttpServletRequest request) {
    ApiErrors error = new ApiErrors("INTERNAL_SERVER_ERROR", ex.getMessage(), request.getRequestURI());
    log.error("Unhandled exception: ", ex);
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiResponse.failure(error, "An unexpected error occurred"));
  }

  @ExceptionHandler(EmailAlreadyExistsException.class)
  public ResponseEntity<ApiResponse<Void>> handleEmailConflict(EmailAlreadyExistsException ex,
      HttpServletRequest request) {
    ApiErrors error = new ApiErrors("EMAIL_EXISTS", ex.getMessage(), request.getRequestURI());
    return ResponseEntity.status(HttpStatus.CONFLICT)
        .body(ApiResponse.failure(error, "Email already in use"));
  }

  @ExceptionHandler(RiderIdAlreadyExistsException.class)
  public ResponseEntity<ApiResponse<Void>> handleRiderIdConflict(RiderIdAlreadyExistsException ex,
      HttpServletRequest request) {
    ApiErrors error = new ApiErrors("RIDER_ID_EXISTS", ex.getMessage(), request.getRequestURI());
    return ResponseEntity.status(HttpStatus.CONFLICT)
        .body(ApiResponse.failure(error, "Rider ID already in use"));
  }

  @ExceptionHandler(InvalidCredentialsException.class)
  public ResponseEntity<ApiResponse<Void>> handleInvalidCredentials(InvalidCredentialsException ex,
      HttpServletRequest request) {
    ApiErrors error = new ApiErrors("AUTH_INVALID_CREDENTIALS", ex.getMessage(), request.getRequestURI());
    log.warn("Invalid credentials on {}: {}", request.getRequestURI(), ex.getMessage());
    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
        .body(ApiResponse.failure(error, ex.getMessage()));
  }

  @ExceptionHandler(UserNotFoundException.class)
  public ResponseEntity<ApiResponse<Void>> handleUserNotFound(UserNotFoundException ex, HttpServletRequest request) {
    ApiErrors error = new ApiErrors("USER_NOT_FOUND", ex.getMessage(), request.getRequestURI());
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(ApiResponse.failure(error, "User not found"));
  }

  @ExceptionHandler(BadCredentialsException.class)
  public ResponseEntity<ApiResponse<Void>> handleBadCredentials(BadCredentialsException ex,
      HttpServletRequest request) {
    ApiErrors error = new ApiErrors("AUTH_INVALID_CREDENTIALS", ex.getMessage(), request.getRequestURI());

    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
        .body(ApiResponse.failure(error, "Login failed"));
  }
}
