package com.ridersclub.notification.service;

import java.util.List;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.notification.dto.NotificationResponse;
import com.ridersclub.notification.entity.Notifications;
import com.ridersclub.notification.repository.NotificationRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public NotificationService(
            NotificationRepository notificationRepository,
            UserRepository userRepository,
            SimpMessagingTemplate messagingTemplate) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional
    public NotificationResponse createAndSend(
            Long userId,
            NotificationType type,
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
                .read(false)
                .build();

        Notifications saved = notificationRepository.save(notification);
        NotificationResponse response = NotificationResponse.fromEntity(saved);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        try {
            messagingTemplate.convertAndSendToUser(
                    user.getUuid(),
                    "/queue/notifications",
                    response);
            messagingTemplate.convertAndSend(
                    "/topic/notifications/" + user.getUuid(),
                    response);
        } catch (Exception e) {
            // Notification persistence is the critical action; socket delivery is best-effort.
            log.warn("Failed to publish notification {} over websocket: {}", response.getId(), e.getMessage());
        }

        return response;
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> getMyNotifications(Long userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(NotificationResponse::fromEntity)
                .toList();
    }

    @Transactional
    public void markAsRead(Long notificationId, Long userId) {
        Notifications notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        if (!notification.getUserId().equals(userId)) {
            throw new RuntimeException("You cannot modify this notification");
        }

        notification.setRead(true);
        notificationRepository.save(notification);
    }

    public Notifications updateReadStatus(Long notificationId, Long userId, boolean read) {
        Notifications notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        if (!notification.getUserId().equals(userId)) {
            throw new RuntimeException("You are not allowed to update this notification");
        }

        notification.setRead(read);
        return notificationRepository.save(notification);
    }

    @Transactional
    public void deleteNotification(Long notificationId, Long userId) {
        Notifications notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        if (!notification.getUserId().equals(userId)) {
            throw new RuntimeException("You are not allowed to delete this notification");
        }

        notificationRepository.delete(notification);
    }

    @Transactional
    public void markAllAsRead(Long userId) {
        List<Notifications> notifications = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);

        for (Notifications notification : notifications) {
            notification.setRead(true);
        }

        notificationRepository.saveAll(notifications);
    }
}
