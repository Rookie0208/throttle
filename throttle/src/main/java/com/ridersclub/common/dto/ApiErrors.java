package com.ridersclub.common.dto;

import java.time.LocalDateTime;

public class ApiErrors {
    private String errorCode;
    private String errorMessage;
    private String path;
    private LocalDateTime timestamp;

    public ApiErrors(String errorCode, String errorMessage, String path) {
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
        this.path = path;
        this.timestamp = LocalDateTime.now();
    }
}
