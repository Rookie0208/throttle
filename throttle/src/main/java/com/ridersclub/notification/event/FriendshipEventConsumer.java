package com.ridersclub.notification.event;

import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * Listens for friendship events published by FriendshipEventPublisher
 * and creates in-app notifications for the relevant users.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class FriendshipEventConsumer {
    private static final String LOG_PREFIX = "FRIEND_EVENT";

    private final NotificationService notificationService;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper;

    @KafkaListener(topics = "${app.kafka.topics.friendship-events:friendship-events-topic}", groupId = "${spring.kafka.consumer.group-id:throttle-notification-group}")
    public void handleFriendshipEvent(String message) {
        log.info("{} action=consume_raw payload={}", LOG_PREFIX, message);
        try {
            JsonNode json = objectMapper.readTree(message);
            String event = json.get("event").asText();
            String senderUuid = json.get("sender").asText();
            String receiverUuid = json.get("receiver").asText();

            if (!"FRIEND_ACCEPTED".equals(event)) {
                log.debug("{} action=ignore_event eventType={}", LOG_PREFIX, event);
                return;
            }

            User sender = userRepository.findByUuid(senderUuid).orElse(null);
            User receiver = userRepository.findByUuid(receiverUuid).orElse(null);

            if (sender == null || receiver == null) {
                log.warn("{} action=consume_blocked reason=user_missing sender={} receiver={}", LOG_PREFIX, senderUuid,
                        receiverUuid);
                return;
            }

            String senderName = sender.getFirstName() + " " + sender.getLastName();

            // Notify the receiver: they now have a new friend
            notificationService.createAndSend(
                    receiver.getId(),
                    NotificationType.NEW_FRIEND,
                    "New Friend Added! 🏍️",
                    "You and " + senderName.trim() + " are now friends.",
                    sender.getId(),
                    "USER");
            log.info("{} action=create_new_friend_notification sender={} receiver={}", LOG_PREFIX, senderUuid,
                    receiverUuid);

        } catch (Exception e) {
            log.error("{} action=consume_failed payload={} reason={}", LOG_PREFIX, message, e.getMessage(), e);
        }
    }
}
