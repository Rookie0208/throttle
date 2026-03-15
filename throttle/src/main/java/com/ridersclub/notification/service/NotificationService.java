package com.ridersclub.notification.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.notification.entity.Notifications;
import com.ridersclub.notification.event.NotificationEvent;
import com.ridersclub.notification.repository.NotificationRepository;
import com.ridersclub.user.entity.User;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private ApplicationEventPublisher eventPublisher;

    public void createNotification(
            Long userId,
            String type,
            String title,
            String message,
            Long referenceId,
            String referenceType) {

        Notifications notification = Notifications.builder()
                .userId(userId)
                .type(type)
                .title(title)
                .message(message)
                .referenceId(referenceId)
                .referenceType(referenceType)
                .isRead(false)
                .createdAt(LocalDateTime.now())
                .build();

        notificationRepository.save(notification);
    }

    // Publish event to handle async saving and later push
    public void publishNotification(
            Long userId,
            String title,
            String message,
            NotificationType type) {

        NotificationEvent event = new NotificationEvent(this, userId, title, message, type);

        eventPublisher.publishEvent(event);
    }

    // Async listener to save notifications
    @Async
    @org.springframework.context.event.EventListener
    public void handleNotificationEvent(NotificationEvent event) {
        Notifications notification = Notifications.builder()
                .userId(event.getUserId())
                .title(event.getTitle())
                .message(event.getMessage())
                .type(event.getType().name())
                .isRead(false)
                .createdAt(LocalDateTime.now())
                .build();

        notificationRepository.save(notification);

        // TODO: In future, push via WebSocket or FCM
    }

    public List<Notifications> getUserNotifications(Long userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public void markAsRead(Long notificationId) {

        Notifications notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        notification.setIsRead(true);
        notificationRepository.save(notification);
    }

}