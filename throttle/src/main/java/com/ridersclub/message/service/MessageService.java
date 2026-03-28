package com.ridersclub.message.service;

import java.util.List;

import com.ridersclub.message.dto.response.MessageDTO;
import com.ridersclub.message.dto.response.MessageResponse;

public interface MessageService {

    MessageResponse sendMessage(
            String senderUuid,
            String groupUuid,
            String message,
            String mediaUrl,
            String messageType);

    List<MessageDTO> getMessages(String groupUuid);

    void markMessagesAsRead(String userUuid, String groupUuid);

    void processMessage(MessageDTO message, String senderUuid);
}