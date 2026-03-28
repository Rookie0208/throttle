package com.ridersclub.message.controller;

import java.security.Principal;
import java.util.List;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.message.dto.response.MessageDTO;
import com.ridersclub.message.dto.response.MessageResponse;
import com.ridersclub.message.service.MessageService;
import com.ridersclub.common.Utils.ApiConstants;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    // // SEND
    // @PostMapping(ApiConstants.Message.SEND)
    // public MessageResponse send(
    // @RequestParam String userUuid,
    // @RequestParam String groupUuid,
    // @RequestParam(required = false) String message,
    // @RequestParam(required = false) String mediaUrl,
    // @RequestParam String messageType) {

    // return messageService.sendMessage(
    // userUuid,
    // groupUuid,
    // message,
    // mediaUrl,
    // messageType);
    // }

    // GET CHAT
    @GetMapping("/api/v1/chat/{groupUuid}")
    public List<MessageDTO> getMessages(
            @PathVariable String groupUuid) {

        return messageService.getMessages(groupUuid);
    }

    // // MARK READ
    // @PostMapping(ApiConstants.Message.MARK_AS_READ)
    // public void markRead(
    // @RequestParam String userUuid,
    // @RequestParam String groupUuid) {

    // messageService.markMessagesAsRead(userUuid, groupUuid);
    // }

    // Websocket
    @MessageMapping("/chat.send")
    public void sendMessage(@Payload MessageDTO message, Principal principal) {

        String userId = principal.getName();
        messageService.processMessage(message, userId);
    }
}