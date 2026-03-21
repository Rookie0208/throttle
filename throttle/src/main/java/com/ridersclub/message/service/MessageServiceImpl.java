package com.ridersclub.message.service;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.message.dto.response.MessageResponse;
import com.ridersclub.message.entity.GroupMessage;
import com.ridersclub.message.entity.MessageRead;
import com.ridersclub.common.enums.MessageType;
import com.ridersclub.message.repository.GroupMessageRepository;
import com.ridersclub.message.repository.MessageReadRepository;
import com.ridersclub.message.service.MessageService;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.ride.repository.RideGroupRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class MessageServiceImpl implements MessageService {

    private final GroupMessageRepository messageRepo;
    private final MessageReadRepository readRepo;
    private final UserRepository userRepository;
    private final RideGroupRepository rideGroupRepository;

    // ===============================
    // SEND MESSAGE
    // ===============================
    @Override
    public MessageResponse sendMessage(
            String senderUuid,
            String groupUuid,
            String message,
            String mediaUrl,
            String messageType) {

        User sender = userRepository.findByUuid(senderUuid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        RideGroup group = rideGroupRepository.findByUuid(groupUuid)
                .orElseThrow(() -> new RuntimeException("Group not found"));

        GroupMessage msg = GroupMessage.builder()
                .uuid(UUID.randomUUID().toString())
                .sender(sender)
                .group(group)
                .message(message)
                .mediaUrl(mediaUrl)
                .messageType(MessageType.valueOf(messageType))
                .edited(false)
                .build();

        messageRepo.save(msg);

        return mapToResponse(msg);
    }

    // ===============================
    // GET GROUP MESSAGES
    // ===============================
    @Override
    @Transactional(readOnly = true)
    public List<MessageResponse> getMessages(String groupUuid) {

        return messageRepo
                .findTop20ByGroup_UuidOrderByCreatedAtDesc(groupUuid)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    // ===============================
    // MARK AS READ
    // ===============================
    @Override
    public void markMessagesAsRead(String userUuid, String groupUuid) {

        User user = userRepository.findByUuid(userUuid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<GroupMessage> messages = messageRepo.findTop20ByGroup_UuidOrderByCreatedAtDesc(groupUuid);

        List<MessageRead> reads = messages.stream()
                .map(msg -> MessageRead.builder()
                        .message(msg)
                        .user(user)
                        .build())
                .toList();

        readRepo.saveAll(reads);
    }

    // ===============================
    // MAPPER
    // ===============================
    private MessageResponse mapToResponse(GroupMessage msg) {
        return new MessageResponse(
                msg.getUuid(),
                msg.getSender().getUuid(),
                msg.getSender().getFirstName(),
                msg.getMessage(),
                msg.getMediaUrl(),
                msg.getMessageType().name(),
                msg.getCreatedAt());
    }
}
