package com.ridersclub.message.dto.response;

import java.time.LocalDateTime;

public record MessageResponse(
        String uuid,
        String senderUuid,
        String senderName,
        String message,
        String mediaUrl,
        String messageType,
        LocalDateTime createdAt) {
}