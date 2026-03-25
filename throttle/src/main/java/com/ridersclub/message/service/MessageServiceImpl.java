package com.ridersclub.message.service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.stream.Collectors;

import com.ridersclub.message.dto.response.MessageDTO;
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
   
        private final SimpMessagingTemplate messagingTemplate;

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
                .collect(Collectors.toList());
    }

    // ===============================
    // MARK AS READ
    // ===============================
    @Override
    public void markMessagesAsRead(String userUuid, String groupUuid) {

        User user = userRepository.findByUuid(userUuid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        List<GroupMessage> messages = messageRepo.findTop20ByGroup_UuidOrderByCreatedAtDesc(groupUuid);

        List<MessageRead> reads = new ArrayList<>();

        for (GroupMessage msg : messages) {
             MessageRead read = MessageRead.builder()
            .message(msg)
            .user(user)
            .build();

        reads.add(read);
}

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


    //websocket
    @Transactional
    public void processMessage(MessageDTO dto) {
        User sender = userRepository.getReferenceById(dto.getSenderId());                       // use this approach when we need to set the entity as a reference without fetching it from the database. It is more efficient than findById() when we only need the reference for associations and not the actual data of the entity. DB calls are saved when we use getReferenceById() instead of findById() because it does not hit the database to fetch the entity data. Instead, it creates a proxy reference that can be used for associations without loading the full entity. This is particularly beneficial in scenarios where we only need to set the reference for relationships and do not require the actual data of the entity, thus improving performance by reducing unnecessary database calls.
        RideGroup group = rideGroupRepository.getReferenceById(dto.getGroupId());

        GroupMessage replyTo = null;

        if (dto.getReplyToId() != null) {
            replyTo = messageRepo.findById(dto.getReplyToId())
                    .orElse(null);
        }

        GroupMessage message = GroupMessage.builder()
                .uuid(UUID.randomUUID().toString())
                .sender(sender)
                .group(group)
                .message(dto.getMessage())
                .mediaUrl(dto.getMediaUrl())
                .messageType(MessageType.valueOf(dto.getMessageType()))
                .replyTo(replyTo)
                .edited(false)
                .build();

        messageRepo.save(message);

        // 🔥 broadcast to group members
        messagingTemplate.convertAndSend(
                "/topic/group." + group.getId(),
                mapToDTO(message)
        );
    }

    private MessageDTO mapToDTO(GroupMessage msg) {

        return MessageDTO.builder()
                .uuid(msg.getUuid())
                .groupId(msg.getGroup().getId())
                .senderId(msg.getSender().getId())
                .message(msg.getMessage())
                .mediaUrl(msg.getMediaUrl())
                .messageType(msg.getMessageType().name())
                .build();
    }
}
