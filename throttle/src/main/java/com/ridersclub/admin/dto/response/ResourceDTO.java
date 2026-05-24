package com.ridersclub.admin.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ResourceDTO {
    private Long id;
    private String resourceKey;
    private String resourceValue;
    private String resourceType; // STRING, BOOLEAN, NUMBER, SECRET, JSON
    private String category;    // FEATURE_FLAGS, API_KEYS, SYSTEM_RATES, OTHER
    private String description;
    private Boolean isSecret;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String updatedBy;

    /**
     * Masks the secret value for secure display on the UI.
     * E.g. "my-super-secret-api-key" becomes "my-s...y"
     */
    public static String maskSecretValue(String decryptedValue) {
        if (decryptedValue == null || decryptedValue.isEmpty()) {
            return "";
        }
        if (decryptedValue.length() <= 8) {
            return "••••••••";
        }
        return decryptedValue.substring(0, 4) + "••••••••" + decryptedValue.substring(decryptedValue.length() - 4);
    }
}
