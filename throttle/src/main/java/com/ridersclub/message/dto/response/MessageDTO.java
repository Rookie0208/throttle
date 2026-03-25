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
    private Long groupId;
    private Long senderId;

    private String message;
    private String mediaUrl;
    private String messageType;

    private String uuid;
    private Long replyToId;
}
