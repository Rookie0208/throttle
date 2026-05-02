package com.ridersclub.admin.service;

import java.io.IOException;
import java.io.InputStream;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.ridersclub.admin.dto.request.UpdateFrontendResourceRequest;
import com.ridersclub.admin.dto.response.FrontendResourceAdminDTO;
import com.ridersclub.admin.entity.FrontendResourceConfigEntity;
import com.ridersclub.admin.repository.FrontendResourceConfigRepository;

@Service
public class FrontendResourceConfigService {
    public static final String FRONTEND_RESOURCE_KEY = "frontend-resource-config";
    private static final String DEFAULT_RESOURCE_PATH = "frontend-resource-config.default.json";
    private static final Map<String, String> SIMPLE_KEY_ALIASES = createSimpleKeyAliases();

    private final FrontendResourceConfigRepository repository;
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    public FrontendResourceConfigService(FrontendResourceConfigRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public JsonNode getFrontendResourceConfig() {
        final JsonNode defaults = loadDefaultConfig();
        final Optional<JsonNode> overrides = repository.findByResourceKey(FRONTEND_RESOURCE_KEY)
            .map(FrontendResourceConfigEntity::getPayload)
            .map(this::tryReadTreeFromString)
            .filter(Optional::isPresent)
            .map(Optional::get);
        return mergeWithDefaults(defaults, overrides.orElse(null));
    }

    @Transactional(readOnly = true)
    public FrontendResourceAdminDTO getAdminFrontendResourceConfig() {
        final Optional<FrontendResourceConfigEntity> existing = repository.findByResourceKey(FRONTEND_RESOURCE_KEY);
        final JsonNode defaults = loadDefaultConfig();
        if (existing.isPresent()) {
            final FrontendResourceConfigEntity entity = existing.get();
            final JsonNode overrides = tryReadTreeFromString(entity.getPayload()).orElse(null);
            final JsonNode config = mergeWithDefaults(defaults, overrides);
            return FrontendResourceAdminDTO.builder()
                .resourceKey(entity.getResourceKey())
                .source("database")
                .updatedBy(entity.getUpdatedBy())
                .updatedAt(entity.getUpdatedAt())
                .entries(toEntries(config))
                .build();
        }

        return FrontendResourceAdminDTO.builder()
            .resourceKey(FRONTEND_RESOURCE_KEY)
            .source("default")
            .updatedBy("system")
            .updatedAt(null)
            .entries(toEntries(defaults))
            .build();
    }

    @Transactional
    public FrontendResourceAdminDTO updateFrontendResourceConfig(
        List<UpdateFrontendResourceRequest.ResourceEntryRequest> entries,
        String updatedBy
    ) {
        final JsonNode config = toObject(entries);
        final JsonNode normalizedConfig = normalizeConfig(config);
        final JsonNode mergedConfig = mergeWithDefaults(loadDefaultConfig(), normalizedConfig);
        final FrontendResourceConfigEntity entity = repository.findByResourceKey(FRONTEND_RESOURCE_KEY)
            .orElseGet(() -> {
                final FrontendResourceConfigEntity created = new FrontendResourceConfigEntity();
                created.setResourceKey(FRONTEND_RESOURCE_KEY);
                return created;
            });

        entity.setPayload(writeValueAsString(mergedConfig));
        entity.setUpdatedBy(updatedBy == null || updatedBy.isBlank() ? "admin" : updatedBy);

        final FrontendResourceConfigEntity saved = repository.save(entity);
        return FrontendResourceAdminDTO.builder()
            .resourceKey(saved.getResourceKey())
            .source("database")
            .updatedBy(saved.getUpdatedBy())
            .updatedAt(saved.getUpdatedAt() == null ? Instant.now() : saved.getUpdatedAt())
            .entries(toEntries(mergedConfig))
            .build();
    }

    private JsonNode normalizeConfig(JsonNode config) {
        try {
            if (config == null || !config.isObject()) {
                throw new IllegalArgumentException("Frontend resource config must be a JSON object");
            }
            return objectMapper.readTree(writeValueAsString(config));
        } catch (IOException ex) {
            throw new IllegalArgumentException("Frontend resource config is not valid JSON", ex);
        }
    }

    private JsonNode loadDefaultConfig() {
        try (InputStream stream = new ClassPathResource(DEFAULT_RESOURCE_PATH).getInputStream()) {
            return objectMapper.readTree(stream);
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to load default frontend resource config", ex);
        }
    }

    private JsonNode readTreeFromString(String value) {
        try {
            return objectMapper.readTree(value);
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to parse stored frontend resource config", ex);
        }
    }

    private Optional<JsonNode> tryReadTreeFromString(String value) {
        try {
            return Optional.ofNullable(objectMapper.readTree(value));
        } catch (IOException ex) {
            return Optional.empty();
        }
    }

    private String writeValueAsString(JsonNode value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to serialize frontend resource config", ex);
        }
    }

    private List<FrontendResourceAdminDTO.ResourceEntryDTO> toEntries(JsonNode config) {
        if (config == null || !config.isObject()) {
            throw new IllegalArgumentException("Frontend resource config must be a JSON object");
        }

        final List<FrontendResourceAdminDTO.ResourceEntryDTO> entries = new ArrayList<>();
        flattenEntries("", config, entries);
        appendPlanAliases(config, entries);
        entries.sort(Comparator.comparing(FrontendResourceConfigService::entrySortKey));
        return entries;
    }

    private JsonNode toObject(List<UpdateFrontendResourceRequest.ResourceEntryRequest> entries) {
        final ObjectNode objectNode = objectMapper.createObjectNode();
        final List<UpdateFrontendResourceRequest.ResourceEntryRequest> aliasEntries = new ArrayList<>();

        for (UpdateFrontendResourceRequest.ResourceEntryRequest entry : entries) {
            final String key = entry.getKey() == null ? "" : entry.getKey().trim();
            if (key.isEmpty()) {
                throw new IllegalArgumentException("Resource entry key cannot be empty");
            }

            if (isPlanAlias(key)) {
                aliasEntries.add(entry);
                continue;
            }

            setPathValue(objectNode, resolveConfigPath(key), entry.getValue());
        }

        for (UpdateFrontendResourceRequest.ResourceEntryRequest entry : aliasEntries) {
            applyPlanAlias(objectNode, entry.getKey().trim(), entry.getValue());
        }
        return objectNode;
    }

    private void flattenEntries(
        String prefix,
        JsonNode node,
        List<FrontendResourceAdminDTO.ResourceEntryDTO> entries
    ) {
        if (node == null) {
            return;
        }

        if (node.isObject()) {
            node.fields().forEachRemaining(field -> {
                final String nextKey = prefix.isEmpty() ? field.getKey() : prefix + "." + field.getKey();
                flattenEntries(nextKey, field.getValue(), entries);
            });
            return;
        }

        entries.add(
            FrontendResourceAdminDTO.ResourceEntryDTO.builder()
                .key(resolveAdminKey(prefix))
                .value(toPlainValue(node))
                .build()
        );
    }

    private Object toPlainValue(JsonNode node) {
        if (node == null || node.isNull()) {
            return null;
        }
        if (node.isTextual()) {
            return node.asText();
        }
        if (node.isBoolean()) {
            return node.asBoolean();
        }
        if (node.isIntegralNumber()) {
            return node.longValue();
        }
        if (node.isFloatingPointNumber()) {
            return node.doubleValue();
        }
        return objectMapper.convertValue(node, Object.class);
    }

    private void setPathValue(ObjectNode root, String path, JsonNode value) {
        final String[] segments = path.split("\\.");
        ObjectNode current = root;

        for (int i = 0; i < segments.length; i++) {
            final String segment = segments[i].trim();
            if (segment.isEmpty()) {
                throw new IllegalArgumentException("Invalid resource key: " + path);
            }

            final boolean isLast = i == segments.length - 1;
            if (isLast) {
                current.set(segment, value);
                return;
            }

            final JsonNode existing = current.get(segment);
            if (existing == null || existing.isNull()) {
                final ObjectNode child = objectMapper.createObjectNode();
                current.set(segment, child);
                current = child;
                continue;
            }

            if (existing instanceof ObjectNode childObject) {
                current = childObject;
                continue;
            }

            final ObjectNode child = objectMapper.createObjectNode();
            current.set(segment, child);
            current = child;
        }
    }

    private void appendPlanAliases(JsonNode config, List<FrontendResourceAdminDTO.ResourceEntryDTO> entries) {
        final JsonNode plansNode = config.path("subscriptions").path("plans");
        if (!plansNode.isArray()) {
            return;
        }

        for (JsonNode planNode : plansNode) {
            if (!planNode.isObject()) {
                continue;
            }

            final String planId = planNode.path("id").asText("");
            if (planId.isBlank()) {
                continue;
            }

            final String priceAlias = switch (planId) {
                case "free" -> "SUBSCRIPTION_FREE_FEE";
                case "rider_plus" -> "SUBSCRIPTION_RIDER_PLUS_FEE";
                case "pro_club" -> "SUBSCRIPTION_PRO_FEE";
                default -> "";
            };

            if (!priceAlias.isBlank() && planNode.has("priceInr")) {
                entries.add(
                    FrontendResourceAdminDTO.ResourceEntryDTO.builder()
                        .key(priceAlias)
                        .value(toPlainValue(planNode.get("priceInr")))
                        .build()
                );
            }

            if ("pro_club".equals(planId) && planNode.has("originalPriceInr")) {
                entries.add(
                    FrontendResourceAdminDTO.ResourceEntryDTO.builder()
                        .key("SUBSCRIPTION_PRO_ORIGINAL_FEE")
                        .value(toPlainValue(planNode.get("originalPriceInr")))
                        .build()
                );
            }
        }
    }

    private void applyPlanAlias(ObjectNode root, String key, JsonNode value) {
        final String planId;
        final String fieldName;

        switch (key) {
            case "SUBSCRIPTION_FREE_FEE" -> {
                planId = "free";
                fieldName = "priceInr";
            }
            case "SUBSCRIPTION_RIDER_PLUS_FEE" -> {
                planId = "rider_plus";
                fieldName = "priceInr";
            }
            case "SUBSCRIPTION_PRO_FEE" -> {
                planId = "pro_club";
                fieldName = "priceInr";
            }
            case "SUBSCRIPTION_PRO_ORIGINAL_FEE" -> {
                planId = "pro_club";
                fieldName = "originalPriceInr";
            }
            default -> throw new IllegalArgumentException("Unsupported resource alias: " + key);
        }

        final ObjectNode subscriptions = getOrCreateObjectNode(root, "subscriptions");
        final ArrayNode plans = getOrCreateArrayNode(subscriptions, "plans");
        final ObjectNode planNode = getOrCreatePlanNode(plans, planId);
        planNode.set(fieldName, value);
    }

    private ObjectNode getOrCreateObjectNode(ObjectNode parent, String fieldName) {
        final JsonNode existing = parent.get(fieldName);
        if (existing == null || existing.isNull()) {
            final ObjectNode child = objectMapper.createObjectNode();
            parent.set(fieldName, child);
            return child;
        }
        if (existing instanceof ObjectNode objectNode) {
            return objectNode;
        }
        throw new IllegalArgumentException("Key conflict on path segment: " + fieldName);
    }

    private ArrayNode getOrCreateArrayNode(ObjectNode parent, String fieldName) {
        final JsonNode existing = parent.get(fieldName);
        if (existing == null || existing.isNull()) {
            final ArrayNode arrayNode = objectMapper.createArrayNode();
            parent.set(fieldName, arrayNode);
            return arrayNode;
        }
        if (existing instanceof ArrayNode arrayNode) {
            return arrayNode;
        }
        throw new IllegalArgumentException("Key conflict on path segment: " + fieldName);
    }

    private ObjectNode getOrCreatePlanNode(ArrayNode plans, String planId) {
        for (JsonNode plan : plans) {
            if (plan instanceof ObjectNode objectNode && planId.equals(objectNode.path("id").asText())) {
                return objectNode;
            }
        }

        final ObjectNode created = objectMapper.createObjectNode();
        created.put("id", planId);
        plans.add(created);
        return created;
    }

    private boolean isPlanAlias(String key) {
        return "SUBSCRIPTION_FREE_FEE".equals(key)
            || "SUBSCRIPTION_RIDER_PLUS_FEE".equals(key)
            || "SUBSCRIPTION_PRO_FEE".equals(key)
            || "SUBSCRIPTION_PRO_ORIGINAL_FEE".equals(key);
    }

    private String resolveAdminKey(String path) {
        return SIMPLE_KEY_ALIASES.entrySet().stream()
            .filter(entry -> entry.getValue().equals(path))
            .map(Map.Entry::getKey)
            .findFirst()
            .orElse(path);
    }

    private String resolveConfigPath(String key) {
        return SIMPLE_KEY_ALIASES.getOrDefault(key, key);
    }

    private static String entrySortKey(FrontendResourceAdminDTO.ResourceEntryDTO entry) {
        final String key = entry.getKey();
        return key.equals(key.toUpperCase()) ? "0_" + key : "1_" + key;
    }

    private static Map<String, String> createSimpleKeyAliases() {
        final Map<String, String> aliases = new LinkedHashMap<>();
        aliases.put("API_BASE_URL", "urls.apiBaseUrl");
        aliases.put("WEBSITE_URL", "urls.websiteBaseUrl");
        aliases.put("WHATSAPP_COMMUNITY_URL", "urls.whatsappCommunityUrl");
        aliases.put("PRIVACY_POLICY_URL", "urls.privacyPolicyUrl");
        aliases.put("TERMS_URL", "urls.termsUrl");
        aliases.put("FREE_PLAN_MAX_BIKES", "limits.freePlanMaxBikes");
        aliases.put("SUBSCRIPTION_TITLE", "subscriptions.title");
        aliases.put("SUBSCRIPTION_DESCRIPTION", "subscriptions.description");
        aliases.put("SUBSCRIPTION_FREE_FEE", "subscriptions.plans.free.priceInr");
        aliases.put("SUBSCRIPTION_RIDER_PLUS_FEE", "subscriptions.plans.rider_plus.priceInr");
        aliases.put("SUBSCRIPTION_PRO_FEE", "subscriptions.plans.pro_club.priceInr");
        aliases.put("SUBSCRIPTION_PRO_ORIGINAL_FEE", "subscriptions.plans.pro_club.originalPriceInr");
        return aliases;
    }

    private JsonNode mergeWithDefaults(JsonNode defaults, JsonNode overrides) {
        if (defaults == null || defaults.isNull()) {
            return overrides == null ? objectMapper.createObjectNode() : overrides.deepCopy();
        }
        if (overrides == null || overrides.isNull()) {
            return defaults.deepCopy();
        }
        if (defaults.isObject() && overrides.isObject()) {
            final ObjectNode merged = defaults.deepCopy();
            overrides.fields().forEachRemaining(entry -> {
                final String key = entry.getKey();
                final JsonNode defaultChild = merged.get(key);
                merged.set(key, mergeWithDefaults(defaultChild, entry.getValue()));
            });
            return merged;
        }
        return overrides.deepCopy();
    }
}
