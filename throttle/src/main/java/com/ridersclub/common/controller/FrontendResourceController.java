package com.ridersclub.common.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.databind.JsonNode;
import com.ridersclub.admin.service.FrontendResourceConfigService;
import com.ridersclub.common.dto.ApiResponse;

@RestController
@RequestMapping("/api/v1/resources/frontend")
public class FrontendResourceController {
    private final FrontendResourceConfigService frontendResourceConfigService;

    public FrontendResourceController(FrontendResourceConfigService frontendResourceConfigService) {
        this.frontendResourceConfigService = frontendResourceConfigService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<JsonNode>> getFrontendResources() {
        return ResponseEntity.ok(
            ApiResponse.success(
                frontendResourceConfigService.getFrontendResourceConfig(),
                "Frontend resources retrieved successfully"
            )
        );
    }
}
