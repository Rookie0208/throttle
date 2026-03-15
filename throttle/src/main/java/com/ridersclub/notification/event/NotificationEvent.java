package com.ridersclub.notification.event;

import org.springframework.context.ApplicationEvent;

import com.ridersclub.common.enums.NotificationType;

public class NotificationEvent extends ApplicationEvent {

    private final Long userId;
    private final String title;
    private final String message;
    private final NotificationType type;

    public NotificationEvent(Object source, Long userId, String title, String message, NotificationType type) {
        super(source);
        this.userId = userId;
        this.title = title;
        this.message = message;
        this.type = type;
    }

    public Long getUserId() { return userId; }
    public String getTitle() { return title; }
    public String getMessage() { return message; }
    public NotificationType getType() { return type; }
}