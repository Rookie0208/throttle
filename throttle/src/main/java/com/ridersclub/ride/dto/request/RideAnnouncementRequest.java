package com.ridersclub.ride.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RideAnnouncementRequest {
    @NotBlank(message = "Announcement message is required")
    @Size(max = 500, message = "Announcement message must be 500 characters or fewer")
    private String message;
}
