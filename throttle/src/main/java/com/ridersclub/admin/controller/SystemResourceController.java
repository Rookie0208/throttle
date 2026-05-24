package com.ridersclub.admin.controller;

import com.ridersclub.admin.dto.response.ResourceDTO;
import com.ridersclub.admin.entity.SystemResource;
import com.ridersclub.admin.security.AdminSecurityContext;
import com.ridersclub.admin.service.SystemResourceService;
import com.ridersclub.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/admin/resources")
@RequiredArgsConstructor
public class SystemResourceController {

    private final SystemResourceService resourceService;
    private final AdminSecurityContext adminSecurityContext;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<ResourceDTO>>> getAllResources() {
        List<ResourceDTO> dtos = resourceService.getAllResources().stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(dtos, "Resources retrieved successfully"));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ResourceDTO>> getResourceById(@PathVariable Long id) {
        SystemResource resource = resourceService.getResourceById(id)
                .orElseThrow(() -> new IllegalArgumentException("Resource config not found for ID: " + id));
        return ResponseEntity.ok(ApiResponse.success(toDTO(resource), "Resource retrieved successfully"));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ResourceDTO>> createResource(@RequestBody SystemResource resource) {
        Long adminId = adminSecurityContext.getCurrentAdminId();
        SystemResource created = resourceService.createResource(adminId, resource);
        return ResponseEntity.ok(ApiResponse.success(toDTO(created), "Resource created successfully"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ResourceDTO>> updateResource(@PathVariable Long id, @RequestBody SystemResource resource) {
        Long adminId = adminSecurityContext.getCurrentAdminId();
        SystemResource updated = resourceService.updateResource(adminId, id, resource);
        return ResponseEntity.ok(ApiResponse.success(toDTO(updated), "Resource updated successfully"));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteResource(@PathVariable Long id) {
        Long adminId = adminSecurityContext.getCurrentAdminId();
        resourceService.deleteResource(adminId, id);
        return ResponseEntity.ok(ApiResponse.success(null, "Resource deleted successfully"));
    }

    private ResourceDTO toDTO(SystemResource entity) {
        String displayValue = entity.getResourceValue();
        if (entity.getIsSecret() != null && entity.getIsSecret()) {
            String decrypted = resourceService.getDecryptedValue(entity.getResourceKey());
            displayValue = ResourceDTO.maskSecretValue(decrypted);
        }
        return ResourceDTO.builder()
                .id(entity.getId())
                .resourceKey(entity.getResourceKey())
                .resourceValue(displayValue)
                .resourceType(entity.getResourceType())
                .category(entity.getCategory())
                .description(entity.getDescription())
                .isSecret(entity.getIsSecret())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .updatedBy(entity.getUpdatedBy())
                .build();
    }
}
