package com.ridersclub.friend.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class FriendshipEventPublisher {

    @Value("${app.kafka.topics.friendship-events:friendship-events-topic}")
    private String friendshipEventsTopic;

    private final KafkaTemplate<String, String> kafkaTemplate;

    public void publishFriendAcceptedEvent(String senderUuid, String receiverUuid) {
        String eventMessage = String.format(
                "{\"event\": \"FRIEND_ACCEPTED\", \"sender\": \"%s\", \"receiver\": \"%s\"}", senderUuid, receiverUuid);
        log.info("Publishing Kafka event for new friendship: {}", eventMessage);

        try {
            kafkaTemplate.send(friendshipEventsTopic, eventMessage);
        } catch (Exception e) {
            log.warn("Kafka broker unreachable. Event dropped gracefully without failing the request: {}",
                    e.getMessage());
        }
    }
}
