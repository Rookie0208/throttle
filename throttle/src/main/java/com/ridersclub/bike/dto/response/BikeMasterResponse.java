package com.ridersclub.bike.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.ridersclub.bike.entity.BikeMaster;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BikeMasterResponse {
    private Long id;
    private String brand;
    private String model;
    private String variant;
    private Integer engineCc;
    private String category;
    private String bikeType;
    private BigDecimal tankCapacity;
    private Integer rangeKm;
    private Integer comfortScore;
    private boolean active;
    private boolean verified;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static BikeMasterResponse from(BikeMaster bike) {
        return new BikeMasterResponse(
                bike.getId(),
                bike.getBrand(),
                bike.getModel(),
                bike.getVariant(),
                bike.getEngineCc(),
                bike.getCategory(),
                bike.getBikeType(),
                bike.getTankCapacity(),
                bike.getRangeKm(),
                bike.getComfortScore(),
                bike.isActive(),
                bike.isVerified(),
                bike.getCreatedAt(),
                bike.getUpdatedAt());
    }
}
