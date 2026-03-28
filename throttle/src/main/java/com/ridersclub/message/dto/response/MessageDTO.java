package com.ridersclub.message.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MessageDTO {
    private String groupId;
    private String senderId;
    private String senderName;

    private String message;
    private String mediaUrl;
    private String messageType;

    private String uuid;
    private Long replyToId;
}
