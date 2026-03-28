package com.ridersclub.friend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PendingRequestDto {
    private Long requestId;
    private String senderUuid;
    private String senderRiderId;
    private String senderFirstName;
    private String senderLastName;
    private String senderProfileImage;
    private LocalDateTime createdAt;
    private int mutualCount;
}
