package com.ridersclub.notification.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.notification.entity.Notification;
import com.ridersclub.notification.event.NotificationEvent;
import com.ridersclub.notification.repository.NotificationRepository;
import com.ridersclub.user.entity.User;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private ApplicationEventPublisher eventPublisher;

    // Publish event to handle async saving and later push
    public void publishNotification(User user, String title, String message, NotificationType type) {
        NotificationEvent event = new NotificationEvent(this, user, title, message, type);
        eventPublisher.publishEvent(event);
    }

    // Async listener to save notifications
    @Async
    @org.springframework.context.event.EventListener
    public void handleNotificationEvent(NotificationEvent event) {
        Notification notification = Notification.builder()
                .user(event.getUser())
                .title(event.getTitle())
                .message(event.getMessage())
                .type(event.getType())
                .build();

        notificationRepository.save(notification);

        // TODO: In future, push via WebSocket or FCM
    }

}