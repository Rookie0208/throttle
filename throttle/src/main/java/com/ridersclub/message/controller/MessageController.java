package com.ridersclub.message.controller;

import java.util.List;

import com.ridersclub.message.dto.response.MessageDTO;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.web.bind.annotation.*;

import com.ridersclub.message.dto.response.MessageResponse;
import com.ridersclub.message.service.MessageService;
import com.ridersclub.common.Utils.ApiConstants;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping(ApiConstants.Message.BASE)
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    // SEND
    @PostMapping(ApiConstants.Message.SEND)
    public MessageResponse send(
            @RequestParam String userUuid,
            @RequestParam String groupUuid,
            @RequestParam(required = false) String message,
            @RequestParam(required = false) String mediaUrl,
            @RequestParam String messageType) {

        return messageService.sendMessage(
                userUuid,
                groupUuid,
                message,
                mediaUrl,
                messageType);
    }

    // GET CHAT
    @GetMapping(ApiConstants.Message.GET_GROUP_MESSAGES)
    public List<MessageResponse> getMessages(
            @PathVariable String groupUuid) {

        return messageService.getMessages(groupUuid);
    }

    // MARK READ
    @PostMapping(ApiConstants.Message.MARK_AS_READ)
    public void markRead(
            @RequestParam String userUuid,
            @RequestParam String groupUuid) {

        messageService.markMessagesAsRead(userUuid, groupUuid);
    }


    //Websocket
    @MessageMapping("/chat.send")
    public void sendMessage(MessageDTO message) {

        messageService.processMessage(message);
    }
}