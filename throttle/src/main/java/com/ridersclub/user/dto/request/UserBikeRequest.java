package com.ridersclub.user.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UserBikeRequest {
    @Size(max = 80)
    private String brand;

    @Size(max = 80)
    private String model;

    @Min(1950)
    @Max(2100)
    private Integer year;

    @Size(max = 150)
    private String variant;

    @Size(max = 50)
    private String category;

    @Size(max = 100)
    private String bikeType;

    @Min(50)
    @Max(5000)
    private Integer engineCc;

    private BigDecimal tankCapacity;

    @Min(50)
    @Max(2000)
    private Integer rangeKm;

    @Min(1)
    @Max(10)
    private Integer comfortScore;

    private Long bikeMasterId;
    private Boolean primary;

    public UserBikeRequest withPrimary(boolean primaryBike) {
        this.primary = primaryBike;
        return this;
    }
}
