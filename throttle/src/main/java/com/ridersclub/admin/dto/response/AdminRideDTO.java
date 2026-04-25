package com.ridersclub.admin.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AdminRideDTO {
    private Long id;
    private String title;
    private String status;
    private String rideType;
    private Long createdBy;
    private LocalDateTime startTime;
}
