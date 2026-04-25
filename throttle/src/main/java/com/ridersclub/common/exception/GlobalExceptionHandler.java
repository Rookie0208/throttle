package com.ridersclub.common.exception;

import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
    String message = ex.getBindingResult().getFieldErrors().stream()
        .map(fieldError -> fieldError.getField() + ": " + fieldError.getDefaultMessage())
        .collect(Collectors.joining(", "));
    if (message.isBlank()) {
      message = "Please check the highlighted fields and try again";
    }
    ApiErrors error = new ApiErrors("VALIDATION_FAILED", message, request.getRequestURI());
    return ResponseEntity.badRequest().body(ApiResponse.failure(error, message));
  }

  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ApiResponse<Void>> illegalArg(IllegalArgumentException ex, HttpServletRequest request) {
    String message = safeMessage(ex.getMessage(), "Invalid request");
    ApiErrors error = new ApiErrors("BAD_REQUEST", message, request.getRequestURI());
    log.error("Invalid argument: ", ex);
    return ResponseEntity.badRequest().body(ApiResponse.failure(error, message));
  }

  @ExceptionHandler(RuntimeException.class)
  public ResponseEntity<ApiResponse<Void>> runtime(RuntimeException ex, HttpServletRequest request) {
    String message = safeMessage(ex.getMessage(), "We couldn't process your request");
    ApiErrors error = new ApiErrors("RUNTIME_ERROR", message, request.getRequestURI());
    log.error("Runtime exception on {}", request.getRequestURI(), ex);
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiResponse.failure(error, message));
  }

  @ExceptionHandler(SecurityException.class)
  public ResponseEntity<ApiResponse<Void>> security(SecurityException ex, HttpServletRequest request) {
    String message = safeMessage(ex.getMessage(), "You are not allowed to perform this action");
    ApiErrors error = new ApiErrors("FORBIDDEN", message, request.getRequestURI());
    log.warn("Security exception on {}: {}", request.getRequestURI(), message);
    return ResponseEntity.status(HttpStatus.FORBIDDEN)
        .body(ApiResponse.failure(error, message));
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiResponse<Void>> generic(Exception ex, HttpServletRequest request) {
    String message = safeMessage(ex.getMessage(), "Something went wrong. Please try again");
    ApiErrors error = new ApiErrors("INTERNAL_SERVER_ERROR", message, request.getRequestURI());
    log.error("Unhandled exception: ", ex);
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiResponse.failure(error, message));
  }

  @ExceptionHandler(EmailAlreadyExistsException.class)
  public ResponseEntity<ApiResponse<Void>> handleEmailConflict(EmailAlreadyExistsException ex,
      HttpServletRequest request) {
    String message = safeMessage(ex.getMessage(), "Email already in use");
    ApiErrors error = new ApiErrors("EMAIL_EXISTS", message, request.getRequestURI());
    return ResponseEntity.status(HttpStatus.CONFLICT)
        .body(ApiResponse.failure(error, message));
  }

  @ExceptionHandler(RiderIdAlreadyExistsException.class)
  public ResponseEntity<ApiResponse<Void>> handleRiderIdConflict(RiderIdAlreadyExistsException ex,
      HttpServletRequest request) {
    String message = safeMessage(ex.getMessage(), "Rider ID already in use");
    ApiErrors error = new ApiErrors("RIDER_ID_EXISTS", message, request.getRequestURI());
    return ResponseEntity.status(HttpStatus.CONFLICT)
        .body(ApiResponse.failure(error, message));
  }

  @ExceptionHandler(InvalidCredentialsException.class)
  public ResponseEntity<ApiResponse<Void>> handleInvalidCredentials(InvalidCredentialsException ex,
      HttpServletRequest request) {
    String message = safeMessage(ex.getMessage(), "Invalid email or password");
    ApiErrors error = new ApiErrors("AUTH_INVALID_CREDENTIALS", message, request.getRequestURI());
    log.warn("Invalid credentials on {}: {}", request.getRequestURI(), message);
    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
        .body(ApiResponse.failure(error, message));
  }

  @ExceptionHandler(UserNotFoundException.class)
  public ResponseEntity<ApiResponse<Void>> handleUserNotFound(UserNotFoundException ex, HttpServletRequest request) {
    String message = safeMessage(ex.getMessage(), "User not found");
    ApiErrors error = new ApiErrors("USER_NOT_FOUND", message, request.getRequestURI());
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(ApiResponse.failure(error, message));
  }

  @ExceptionHandler(BadCredentialsException.class)
  public ResponseEntity<ApiResponse<Void>> handleBadCredentials(BadCredentialsException ex,
      HttpServletRequest request) {
    String message = safeMessage(ex.getMessage(), "Invalid email or password");
    ApiErrors error = new ApiErrors("AUTH_INVALID_CREDENTIALS", message, request.getRequestURI());

    return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
        .body(ApiResponse.failure(error, message));
  }

  private String safeMessage(String message, String fallback) {
    return message == null || message.isBlank() ? fallback : message;
  }
}
