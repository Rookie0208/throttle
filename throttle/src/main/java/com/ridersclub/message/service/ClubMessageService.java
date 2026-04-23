package com.ridersclub.message.service;

import java.util.List;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.MessageType;
import com.ridersclub.message.dto.response.MessageDTO;
import com.ridersclub.message.entity.ClubMessage;
import com.ridersclub.message.repository.ClubMessageRepository;
import com.ridersclub.ride.entity.Club;
import com.ridersclub.ride.entity.ClubSubgroup;
import com.ridersclub.ride.service.ClubService;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class ClubMessageService {

    private final SimpMessagingTemplate messagingTemplate;
    private final ClubMessageRepository clubMessageRepository;
    private final ClubService clubService;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<MessageDTO> getMessages(String channelUuid, String currentUserUuid) {
        if (isClubChannel(channelUuid)) {
            clubService.getClubDetails(channelUuid, currentUserUuid);
            return clubMessageRepository.findTop50ByClub_UuidAndSubgroupIsNullOrderByCreatedAtDesc(channelUuid).stream()
                    .map(this::toDto)
                    .toList();
        }

        final ClubSubgroup subgroup = clubService.findSubgroup(channelUuid);
        if (!clubService.isSubgroupMember(subgroup.getUuid(), currentUserUuid)) {
            throw new RuntimeException("Join this subgroup to continue");
        }
        return clubMessageRepository.findTop50BySubgroup_UuidOrderByCreatedAtDesc(channelUuid).stream()
                .map(this::toDto)
                .toList();
    }

    public void processMessage(MessageDTO dto, String senderUuid) {
        final User sender = userRepository.findByUuid(senderUuid)
                .orElseThrow(() -> new RuntimeException("User not found"));
        final String channelUuid = dto.getGroupId();

        final ClubMessage message;
        if (isClubChannel(channelUuid)) {
            final Club club = clubService.findClub(channelUuid);
            if (!clubService.isClubMember(club.getUuid(), senderUuid)) {
                throw new RuntimeException("Join this club to send messages");
            }
            message = ClubMessage.builder()
                    .uuid(UserUtility.generateUUID("CCHAT"))
                    .sender(sender)
                    .club(club)
                    .message(dto.getMessage())
                    .messageType(MessageType.valueOf(dto.getMessageType()))
                    .build();
        } else {
            final ClubSubgroup subgroup = clubService.findSubgroup(channelUuid);
            if (!clubService.isSubgroupMember(subgroup.getUuid(), senderUuid)) {
                throw new RuntimeException("Join this subgroup to send messages");
            }
            message = ClubMessage.builder()
                    .uuid(UserUtility.generateUUID("CCHAT"))
                    .sender(sender)
                    .club(subgroup.getClub())
                    .subgroup(subgroup)
                    .message(dto.getMessage())
                    .messageType(MessageType.valueOf(dto.getMessageType()))
                    .build();
        }

        final ClubMessage saved = clubMessageRepository.save(message);
        messagingTemplate.convertAndSend("/topic/club." + channelUuid, toDto(saved));
    }

    private boolean isClubChannel(String channelUuid) {
        return channelUuid != null && channelUuid.startsWith("CLUB-");
    }

    private MessageDTO toDto(ClubMessage message) {
        return MessageDTO.builder()
                .uuid(message.getUuid())
                .groupId(message.getSubgroup() == null ? message.getClub().getUuid() : message.getSubgroup().getUuid())
                .senderId(message.getSender().getUuid())
                .senderName(message.getSender().getFirstName())
                .message(message.getMessage())
                .messageType(message.getMessageType().name())
                .build();
    }
}
