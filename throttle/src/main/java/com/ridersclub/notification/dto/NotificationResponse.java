package com.ridersclub.notification.dto;

import java.time.LocalDateTime;

import com.ridersclub.notification.entity.Notifications;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationResponse {

    private Long id;
    private Long userId;
    private String type;
    private String title;
    private String message;
    private Long referenceId;
    private String referenceType;
    private boolean read;
    private LocalDateTime createdAt;

    public static NotificationResponse fromEntity(Notifications notification) {
        return NotificationResponse.builder()
                .id(notification.getId())
                .userId(notification.getUserId())
                .type(notification.getType())
                .title(notification.getTitle())
                .message(notification.getMessage())
                .referenceId(notification.getReferenceId())
                .referenceType(notification.getReferenceType())
                .read(notification.isRead())
                .createdAt(notification.getCreatedAt())
                .build();
    }
}