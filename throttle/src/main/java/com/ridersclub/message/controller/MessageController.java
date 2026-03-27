package com.ridersclub.message.controller;

import java.security.Principal;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;

import com.ridersclub.message.dto.response.MessageDTO;
import com.ridersclub.message.service.MessageService;

import lombok.RequiredArgsConstructor;

@Controller

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

    // // GET CHAT
    // @GetMapping(ApiConstants.Message.GET_GROUP_MESSAGES)
    // public List<MessageResponse> getMessages(
    // @PathVariable String groupUuid) {

    // return messageService.getMessages(groupUuid);
    // }

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