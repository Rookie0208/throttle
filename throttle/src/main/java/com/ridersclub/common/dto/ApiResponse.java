package com.ridersclub.common.dto;

import java.time.LocalDateTime;

public class ApiResponse<T> {
    private String status; // SUCCESS / FAILED
    private T data; // actual response payload
    private ApiErrors error; // null if success
    private String message;
    private LocalDateTime timestamp;

    public ApiResponse() {
        this.timestamp = LocalDateTime.now();
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }

    public ApiErrors getError() {
        return error;
    }

    public void setError(ApiErrors error) {
        this.error = error;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public static <T> ApiResponse<T> success(T data, String message) {
        ApiResponse<T> response = new ApiResponse<>();
        response.status = "SUCCESS";
        response.data = data;
        response.message = message;
        return response;
    }

    public static <T> ApiResponse<T> failure(ApiErrors error, String message) {
        ApiResponse<T> response = new ApiResponse<>();
        response.status = "FAILED";
        response.error = error;
        response.message = message;
        return response;
    }
}
