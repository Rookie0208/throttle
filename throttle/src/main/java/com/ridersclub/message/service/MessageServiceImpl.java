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
import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.MessageType;
import com.ridersclub.common.enums.UuidPrefix;
import com.ridersclub.message.repository.GroupMessageRepository;
import com.ridersclub.message.repository.MessageReadRepository;
import com.ridersclub.message.service.MessageService;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.ride.repository.GroupMemberRepository;
import com.ridersclub.ride.repository.RideParticipantRepository;
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
        private final GroupMemberRepository groupMemberRepository;
        private final RideParticipantRepository rideParticipantRepository;

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
                validateMessageAccess(group, sender, true);

                GroupMessage msg = GroupMessage.builder()
                                .uuid(UserUtility.generateUUID(UuidPrefix.CHAT.name()))
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
        public List<MessageDTO> getMessages(String groupUuid) {
                List<MessageDTO> msgs = messageRepo
                                .findTop20ByGroup_UuidOrderByCreatedAtDesc(groupUuid)
                                .stream()
                                .map(this::mapToDTO)
                                .collect(Collectors.toList());
                return msgs;
        }

        // ===============================
        // MARK AS READ
        // ===============================
        @Override
        public void markMessagesAsRead(String userUuid, String groupUuid) {

                User user = userRepository.findByUuid(userUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = rideGroupRepository.findByUuid(groupUuid)
                                .orElseThrow(() -> new RuntimeException("Group not found"));
                validateMessageAccess(group, user, false);

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

        // websocket
        @Transactional
        public void processMessage(MessageDTO dto, String senderUuid) {
                User sender = userRepository.findByUuid(senderUuid)
                                .orElseThrow(() -> new RuntimeException("User not found"));
                RideGroup group = rideGroupRepository.findByUuid(dto.getGroupId())
                                .orElseThrow(() -> new RuntimeException("Group not found"));
                validateMessageAccess(group, sender, true);

                GroupMessage replyTo = null;

                if (dto.getReplyToId() != null) {
                        replyTo = messageRepo.findById(dto.getReplyToId())
                                        .orElse(null);
                }

                GroupMessage message = GroupMessage.builder()
                                .uuid(UserUtility.generateUUID(UuidPrefix.CHAT.name()))
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
                                "/topic/group." + group.getUuid(),
                                mapToDTO(message));
        }

        private MessageDTO mapToDTO(GroupMessage msg) {

                return MessageDTO.builder()
                                .uuid(msg.getUuid())
                                .groupId(msg.getGroup().getUuid())
                                .senderId(msg.getSender().getUuid())
                                .senderName(msg.getSender().getFirstName())
                                .message(msg.getMessage())
                                .mediaUrl(msg.getMediaUrl())
                                .messageType(msg.getMessageType().name())
                                .build();
        }

        private void validateMessageAccess(RideGroup group, User user, boolean sending) {
                boolean isRideParticipant = rideParticipantRepository.existsByRide_IdAndUser_Id(
                                group.getRide().getId(),
                                user.getId());
                boolean isGroupMember = groupMemberRepository.existsByGroup_IdAndUser_Id(group.getId(), user.getId());
                boolean isAccessible = (group.getVisibility() == com.ridersclub.common.enums.Visibility.PUBLIC
                                && isRideParticipant) || isGroupMember;

                if (!isAccessible) {
                        throw new RuntimeException("You are not allowed to access this group");
                }

                if (!sending) {
                        return;
                }

                if (isGroupManager(group, user)) {
                        return;
                }

                if (!Boolean.TRUE.equals(group.getMembersCanSendMessages())) {
                        throw new RuntimeException("Members cannot send messages in this subgroup");
                }
        }

        private boolean isGroupManager(RideGroup group, User user) {
                return groupMemberRepository.findByGroup_IdAndUser_Id(group.getId(), user.getId())
                                .map(member -> {
                                        String role = member.getRole() == null ? "" : member.getRole().trim().toUpperCase();
                                        return role.equals("ADMIN") || role.equals("CAPTAIN");
                                })
                                .orElse(false)
                                || rideParticipantRepository.findByRide_UuidAndUser_Uuid(group.getRide().getUuid(), user.getUuid())
                                                .map(member -> member.getRole() == com.ridersclub.common.enums.Role.ADMIN
                                                                || member.getRole() == com.ridersclub.common.enums.Role.CAPTAIN)
                                                .orElse(false);
        }
}
