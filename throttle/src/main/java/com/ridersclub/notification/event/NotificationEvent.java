package com.ridersclub.notification.event;

import org.springframework.context.ApplicationEvent;

import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.user.entity.User;

public class NotificationEvent extends ApplicationEvent {

    private final User user;
    private final String title;
    private final String message;
    private final NotificationType type;

    public NotificationEvent(Object source, User user, String title, String message, NotificationType type) {
        super(source);
        this.user = user;
        this.title = title;
        this.message = message;
        this.type = type;
    }

    public User getUser() { return user; }
    public String getTitle() { return title; }
    public String getMessage() { return message; }
    public NotificationType getType() { return type; }
}