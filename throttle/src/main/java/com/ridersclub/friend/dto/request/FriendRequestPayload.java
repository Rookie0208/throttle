package com.ridersclub.friend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class FriendRequestPayload {
    @NotBlank(message = "Receiver UUID cannot be blank")
    private String receiverUuid;
}
