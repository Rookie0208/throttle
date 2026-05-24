package com.ridersclub.admin.service;

import com.ridersclub.admin.entity.SystemResource;
import com.ridersclub.admin.repository.SystemResourceRepository;
import com.ridersclub.admin.kafka.AuditProducer;
import com.ridersclub.admin.kafka.AuditLogEvent;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Counter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.ApplicationArguments;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class SystemResourceService implements ApplicationRunner {

    private final SystemResourceRepository repository;
    private final EncryptionService encryptionService;
    private final AuditProducer auditProducer;
    private final MeterRegistry meterRegistry;

    @Override
    public void run(ApplicationArguments args) {
        log.info("SystemResourceService: Checking database for default resources to bootstrap...");
        if (repository.count() == 0) {
            log.info("SystemResourceService: No resources found. Bootstrapping default configuration database...");
            bootstrapDefaultResources();
        } else {
            log.info("SystemResourceService: Database already bootstrapped with resources.");
        }
    }

    private void bootstrapDefaultResources() {
        // Feature Flags
        saveDefaultResource("FEATURE_CLUBS_ENABLED", "true", "BOOLEAN", "FEATURE_FLAGS", "If enabled, show the Clubs persistent communities section in client applications.", false);
        saveDefaultResource("FEATURE_MAINTENANCE_MODE", "false", "BOOLEAN", "FEATURE_FLAGS", "Global site-wide maintenance mode. If enabled, non-admin actions are blocked.", false);
        saveDefaultResource("FEATURE_GOOGLE_LOGIN", "true", "BOOLEAN", "FEATURE_FLAGS", "Enable social authentication using Google Client API.", false);
        saveDefaultResource("FEATURE_RIDE_SHARING", "true", "BOOLEAN", "FEATURE_FLAGS", "Enable group riding creation, invite, and location sharing features.", false);
        saveDefaultResource("FEATURE_ELASTIC_LOGGING", "true", "BOOLEAN", "FEATURE_FLAGS", "Stream administrative audits dynamically to Elasticsearch.", false);

        // API Keys (Secrets - encrypted)
        saveDefaultResource("GOOGLE_CLIENT_ID", "570110967969-otsco0oana772nulppb5cslvvks9en9k.apps.googleusercontent.com", "SECRET", "API_KEYS", "Google OAuth Web Client ID for authentication.", true);
        saveDefaultResource("GOOGLE_MAPS_KEY", "AIzaSyMockKeyForMapsIntegrationPartOne", "SECRET", "API_KEYS", "Google Maps API Key used for maps rendering and geolocation search.", true);
        saveDefaultResource("STRIPE_API_SECRET", "sk_test_MockStripeKeyForRidersClubBilling", "SECRET", "API_KEYS", "Stripe Payment Gateway Secret API Key.", true);

        // System Settings
        saveDefaultResource("FREE_PLAN_BIKE_LIMIT", "3", "NUMBER", "SYSTEM_RATES", "Maximum number of garage bikes allowed for standard/free tier users.", false);
        saveDefaultResource("RIDE_BASE_FARE", "50.0", "NUMBER", "SYSTEM_RATES", "Base platform fare in local currency for ride computations.", false);
        saveDefaultResource("RIDE_RATE_PER_KM", "12.5", "NUMBER", "SYSTEM_RATES", "Rate per kilometer applied to calculated route distances.", false);
        saveDefaultResource("MAX_MEMBERS_PER_CLUB", "500", "NUMBER", "SYSTEM_RATES", "Maximum number of members allowed in a standard Club.", false);
        saveDefaultResource("AUTO_BLOCK_REPORTS_THRESHOLD", "5", "NUMBER", "SYSTEM_RATES", "Number of active reports before a user is automatically flagged/blocked.", false);

        log.info("SystemResourceService: Seeding completed successfully.");
    }

    private void saveDefaultResource(String key, String value, String type, String category, String description, boolean isSecret) {
        String finalValue = isSecret ? encryptionService.encrypt(value) : value;
        SystemResource resource = SystemResource.builder()
                .resourceKey(key)
                .resourceValue(finalValue)
                .resourceType(type)
                .category(category)
                .description(description)
                .isSecret(isSecret)
                .build();
        repository.save(resource);
    }

    /**
     * Resolves the raw decrypted value of a resource config.
     * Cached to reduce DB load in critical runtime flows.
     */
    @Cacheable(value = "resources", key = "#resourceKey")
    public String getDecryptedValue(String resourceKey) {
        log.debug("SystemResourceService: Fetching resource key='{}' from database (cache miss)", resourceKey);
        return repository.findByResourceKey(resourceKey)
                .map(res -> res.getIsSecret() ? encryptionService.decrypt(res.getResourceValue()) : res.getResourceValue())
                .orElse(null);
    }

    /**
     * Helper to resolve boolean feature flags.
     */
    public boolean isFeatureEnabled(String featureKey) {
        String val = getDecryptedValue(featureKey);
        return Boolean.parseBoolean(val);
    }

    /**
     * Fetches all feature flags as a key-value map.
     * Used by client applications to dynamically enable/disable sections.
     */
    public Map<String, Boolean> getFeatureFlags() {
        return repository.findByCategory("FEATURE_FLAGS").stream()
                .collect(Collectors.toMap(
                        SystemResource::getResourceKey,
                        res -> Boolean.parseBoolean(res.getResourceValue())
                ));
    }

    public List<SystemResource> getAllResources() {
        return repository.findAll();
    }

    public Optional<SystemResource> getResourceById(Long id) {
        return repository.findById(id);
    }

    @Transactional
    @CacheEvict(value = "resources", allEntries = true)
    public SystemResource createResource(Long adminId, SystemResource resource) {
        log.info("ADMIN action=CREATE_RESOURCE adminId={} key={}", adminId, resource.getResourceKey());

        if (resource.getIsSecret() != null && resource.getIsSecret()) {
            resource.setResourceValue(encryptionService.encrypt(resource.getResourceValue()));
        }

        SystemResource saved = repository.save(resource);
        publishAudit("CREATE_RESOURCE", adminId, saved.getId());
        return saved;
    }

    @Transactional
    @CacheEvict(value = "resources", allEntries = true)
    public SystemResource updateResource(Long adminId, Long id, SystemResource updatedData) {
        log.info("ADMIN action=UPDATE_RESOURCE adminId={} targetId={}", adminId, id);

        SystemResource existing = repository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Resource config not found for ID: " + id));

        existing.setDescription(updatedData.getDescription());
        existing.setResourceType(updatedData.getResourceType());
        existing.setCategory(updatedData.getCategory());
        existing.setUpdatedBy(updatedData.getUpdatedBy());

        // Check if a new value is being set
        String incomingValue = updatedData.getResourceValue();
        if (incomingValue != null && !incomingValue.trim().isEmpty()) {
            boolean isMasked = incomingValue.contains("••••") || incomingValue.equals("••••••••");
            if (!isMasked) {
                // It is a real value update (not the masked placeholder)
                if (existing.getIsSecret()) {
                    existing.setResourceValue(encryptionService.encrypt(incomingValue));
                } else {
                    existing.setResourceValue(incomingValue);
                }
                log.info("SystemResourceService: Updating resource value for key={}", existing.getResourceKey());
            }
        }

        SystemResource saved = repository.save(existing);
        publishAudit("UPDATE_RESOURCE", adminId, saved.getId());
        return saved;
    }

    @Transactional
    @CacheEvict(value = "resources", allEntries = true)
    public void deleteResource(Long adminId, Long id) {
        log.info("ADMIN action=DELETE_RESOURCE adminId={} targetId={}", adminId, id);
        SystemResource existing = repository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Resource config not found for ID: " + id));

        repository.delete(existing);
        publishAudit("DELETE_RESOURCE", adminId, id);
    }

    private void publishAudit(String action, Long adminId, Long targetId) {
        log.info("AUDIT_EVENT action={} adminId={} targetId={}", action, adminId, targetId);
        String timestamp = Instant.now().toString();
        AuditLogEvent event = AuditLogEvent.builder()
                .action(action)
                .adminId(adminId)
                .targetId(targetId)
                .timestamp(timestamp)
                .build();
        auditProducer.publishAuditLog(event);
        Counter.builder("admin_actions_total")
                .tag("action", action)
                .description("Total number of admin actions taken")
                .register(meterRegistry)
                .increment();
    }
}
