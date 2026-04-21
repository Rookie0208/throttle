package com.ridersclub.bike.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class BikeMasterAdminRequest {
    @NotBlank
    @Size(max = 100)
    private String brand;

    @NotBlank
    @Size(max = 100)
    private String model;

    @NotBlank
    @Size(max = 150)
    private String variant;

    @NotNull
    @Min(0)
    @Max(5000)
    private Integer engineCc;

    @NotBlank
    @Size(max = 30)
    private String category;

    @NotBlank
    @Size(max = 100)
    private String bikeType;

    @NotNull
    private BigDecimal tankCapacity;

    @NotNull
    @Min(50)
    @Max(2000)
    private Integer rangeKm;

    @NotNull
    @Min(1)
    @Max(10)
    private Integer comfortScore;

    private Boolean active;
    private Boolean verified;
}
