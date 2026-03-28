package com.ridersclub.common.exception;

public class RiderIdAlreadyExistsException extends RuntimeException {
    public RiderIdAlreadyExistsException(String message) {
        super(message);
    }
}
