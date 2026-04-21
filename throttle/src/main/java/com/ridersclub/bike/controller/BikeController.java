package com.ridersclub.bike.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.bike.dto.request.BikeMasterAdminRequest;
import com.ridersclub.bike.dto.response.BikeMasterResponse;
import com.ridersclub.bike.service.BikeRegistryService;
import com.ridersclub.common.dto.ApiResponse;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/bikes")
@RequiredArgsConstructor
public class BikeController {
    private final BikeRegistryService bikeRegistryService;

    @GetMapping("/brands")
    public ResponseEntity<ApiResponse<List<String>>> brands(
            @RequestParam(value = "query", required = false) String query) {
        return ResponseEntity.ok(ApiResponse.success(
                bikeRegistryService.findBrands(query),
                "Bike brands fetched successfully"));
    }

    @GetMapping("/models")
    public ResponseEntity<ApiResponse<List<String>>> models(
            @RequestParam("brand") String brand,
            @RequestParam(value = "query", required = false) String query) {
        return ResponseEntity.ok(ApiResponse.success(
                bikeRegistryService.findModels(brand, query),
                "Bike models fetched successfully"));
    }

    @GetMapping("/variants")
    public ResponseEntity<ApiResponse<List<BikeMasterResponse>>> variants(
            @RequestParam("brand") String brand,
            @RequestParam("model") String model,
            @RequestParam(value = "query", required = false) String query) {
        return ResponseEntity.ok(ApiResponse.success(
                bikeRegistryService.findVariants(brand, model, query),
                "Bike variants fetched successfully"));
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<BikeMasterResponse>>> search(
            @RequestParam(value = "query", required = false) String query) {
        return ResponseEntity.ok(ApiResponse.success(
                bikeRegistryService.search(query),
                "Bike search completed successfully"));
    }

    @GetMapping("/admin")
    public ResponseEntity<ApiResponse<List<BikeMasterResponse>>> adminSearch(
            Authentication authentication,
            @RequestParam(value = "query", required = false) String query) {
        assertAdmin(authentication);
        return ResponseEntity.ok(ApiResponse.success(
                bikeRegistryService.adminSearch(query),
                "Bike catalog admin view fetched successfully"));
    }

    @PostMapping("/admin")
    public ResponseEntity<ApiResponse<BikeMasterResponse>> create(
            Authentication authentication,
            @Valid @RequestBody BikeMasterAdminRequest request) {
        assertAdmin(authentication);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(bikeRegistryService.createBike(request), "Bike created successfully"));
    }

    @PutMapping("/admin/{bikeId}")
    public ResponseEntity<ApiResponse<BikeMasterResponse>> update(
            Authentication authentication,
            @PathVariable("bikeId") Long bikeId,
            @Valid @RequestBody BikeMasterAdminRequest request) {
        assertAdmin(authentication);
        return ResponseEntity.ok(ApiResponse.success(
                bikeRegistryService.updateBike(bikeId, request),
                "Bike updated successfully"));
    }

    @PostMapping("/admin/{bikeId}/verify")
    public ResponseEntity<ApiResponse<BikeMasterResponse>> verify(
            Authentication authentication,
            @PathVariable("bikeId") Long bikeId) {
        assertAdmin(authentication);
        return ResponseEntity.ok(ApiResponse.success(
                bikeRegistryService.verifyBike(bikeId),
                "Bike verified successfully"));
    }

    @PostMapping("/admin/{bikeId}/deactivate")
    public ResponseEntity<ApiResponse<BikeMasterResponse>> deactivate(
            Authentication authentication,
            @PathVariable("bikeId") Long bikeId) {
        assertAdmin(authentication);
        return ResponseEntity.ok(ApiResponse.success(
                bikeRegistryService.deactivateBike(bikeId),
                "Bike deactivated successfully"));
    }

    private void assertAdmin(Authentication authentication) {
        boolean isAdmin = authentication != null
                && authentication.getAuthorities() != null
                && authentication.getAuthorities().stream()
                        .anyMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()));
        if (!isAdmin) {
            throw new SecurityException("Admin access required");
        }
    }
}
