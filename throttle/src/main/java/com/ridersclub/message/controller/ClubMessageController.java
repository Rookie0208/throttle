package com.ridersclub.message.controller;

import java.security.Principal;
import java.util.List;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.message.dto.response.MessageDTO;
import com.ridersclub.message.service.ClubMessageService;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
public class ClubMessageController {

    private final ClubMessageService clubMessageService;

    @GetMapping("/api/v1/clubs/chat/{channelUuid}")
    public List<MessageDTO> getMessages(
            @PathVariable String channelUuid,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return clubMessageService.getMessages(channelUuid, currentUserUuid);
    }

    @MessageMapping("/club-chat.send")
    public void sendMessage(@Payload MessageDTO message, Principal principal) {
        clubMessageService.processMessage(message, principal.getName());
    }
}
