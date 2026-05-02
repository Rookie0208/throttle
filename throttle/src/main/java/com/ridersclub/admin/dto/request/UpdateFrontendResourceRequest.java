package com.ridersclub.admin.dto.request;

import java.util.List;

import com.fasterxml.jackson.databind.JsonNode;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateFrontendResourceRequest {
    @Valid
    @NotEmpty
    private List<ResourceEntryRequest> entries;

    @Getter
    @Setter
    public static class ResourceEntryRequest {
        @NotBlank
        private String key;

        @NotNull
        private JsonNode value;
    }
}
