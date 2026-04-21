package com.ridersclub.bike.service;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jsoup.Jsoup;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.ridersclub.bike.dto.request.BikeMasterAdminRequest;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class BikeCatalogBootstrapService implements ApplicationRunner {
    private static final Pattern JSON_NAME_PATTERN = Pattern.compile("\"name\"\\s*:\\s*\"([^\"]+)\"");

    private final BikeRegistryService bikeRegistryService;

    @Value("${bike.catalog.external-import.enabled:true}")
    private boolean externalImportEnabled;

    @Value("${bike.catalog.external-import.timeout-ms:3000}")
    private int timeoutMs;

    @Override
    public void run(ApplicationArguments args) {
        try {
            int seeded = bikeRegistryService.seedIfEmpty(fallbackSeedData());
            if (seeded > 0) {
                log.info("Bootstrapped bike catalog with curated seed data: {} records", seeded);
                return;
            }

            log.info("Bike catalog already contains data. Skipping external import to preserve existing records.");
            return;
        } catch (Exception error) {
            log.warn("Curated bike seed failed. Trying external import fallback. reason={}", error.getMessage());
        }

        if (!externalImportEnabled) {
            log.warn("External bike import is disabled and seed bootstrap failed. Catalog was not bootstrapped.");
            return;
        }

        int imported = 0;
        imported += tryImport("BikeDekho", "https://www.bikedekho.com/new-bikes");
        imported += tryImport("ZigWheels", "https://www.zigwheels.com/newbikes");
        imported += tryImport("91Wheels", "https://www.91wheels.com/bikes");

        if (imported > 0) {
            log.info("Bootstrapped bike catalog from external fallback sources: {} records", imported);
            return;
        }

        log.warn("Bike catalog bootstrap failed. No seed data or external fallback data was imported.");
    }

    private int tryImport(String source, String url) {
        try {
            String html = Jsoup.connect(url)
                    .userAgent("Mozilla/5.0")
                    .timeout((int) Duration.ofMillis(timeoutMs).toMillis())
                    .ignoreHttpErrors(true)
                    .get()
                    .html();
            List<BikeMasterAdminRequest> extracted = extractCandidates(html);
            int imported = bikeRegistryService.importCatalog(extracted);
            log.info("{} import attempt finished. candidates={}, imported={}", source, extracted.size(), imported);
            return imported;
        } catch (Exception error) {
            log.warn("{} fallback import failed. reason={}", source, error.getMessage());
            return 0;
        }
    }

    private List<BikeMasterAdminRequest> extractCandidates(String html) {
        List<BikeMasterAdminRequest> candidates = new ArrayList<>();
        Matcher matcher = JSON_NAME_PATTERN.matcher(html);
        while (matcher.find() && candidates.size() < 15) {
            String rawName = matcher.group(1);
            if (rawName == null || rawName.isBlank() || rawName.length() > 80 || !rawName.contains(" ")) {
                continue;
            }
            String[] parts = rawName.trim().split("\\s+");
            if (parts.length < 2) {
                continue;
            }

            BikeMasterAdminRequest request = new BikeMasterAdminRequest();
            request.setBrand(parts[0]);
            request.setModel(parts.length > 2 ? parts[1] : rawName.trim());
            request.setVariant(rawName.trim());
            request.setEngineCc(350);
            request.setCategory("commuter");
            request.setBikeType("Motorcycle");
            request.setTankCapacity(BigDecimal.valueOf(12.0));
            request.setRangeKm(420);
            request.setComfortScore(7);
            request.setActive(true);
            request.setVerified(true);
            candidates.add(request);
        }
        return candidates;
    }

    private List<BikeMasterAdminRequest> fallbackSeedData() {
        return List.of(
                seed("Royal Enfield", "Hunter 350", "Hunter 350 Retro", 349, "cruiser", "Motorcycle", 13.0, 455, 8),
                seed("Royal Enfield", "Classic 350", "Classic 350 Dark", 349, "cruiser", "Motorcycle", 13.0, 455, 9),
                seed("Royal Enfield", "Himalayan 450", "Himalayan 450 Base", 452, "adv", "Motorcycle", 17.0, 510, 8),
                seed("KTM", "Duke 390", "Duke 390 Gen 3", 399, "sport", "Motorcycle", 15.0, 420, 7),
                seed("TVS", "Apache RTR 310", "Apache RTR 310 Arsenal Black", 312, "sport", "Motorcycle", 11.0, 330, 7),
                seed("Bajaj", "Pulsar NS200", "Pulsar NS200 STD", 199, "sport", "Motorcycle", 12.0, 420, 7),
                seed("Hero", "Xpulse 200 4V", "Xpulse 200 4V Pro", 199, "adv", "Motorcycle", 13.0, 455, 8),
                seed("Honda", "CB350", "CB350 DLX", 348, "cruiser", "Motorcycle", 15.2, 530, 8),
                seed("Yamaha", "MT-15", "MT-15 V2 Deluxe", 155, "sport", "Motorcycle", 10.0, 450, 7),
                seed("Yamaha", "R15", "R15 V4 Racing Blue", 155, "sport", "Motorcycle", 11.0, 495, 6),
                seed("Suzuki", "V-Strom SX", "V-Strom SX Ride Connect", 249, "adv", "Motorcycle", 12.0, 420, 8),
                seed("Triumph", "Speed 400", "Speed 400 STD", 398, "sport", "Motorcycle", 13.0, 390, 8),
                seed("TVS", "Ronin", "Ronin TD Special Edition", 225, "commuter", "Motorcycle", 14.0, 560, 8),
                seed("Honda", "Shine 125", "Shine 125 Drum", 123, "commuter", "Motorcycle", 10.5, 650, 8),
                seed("Bajaj", "Chetak", "Chetak Premium", 0, "commuter", "Electric Scooter", 0.0, 127, 8));
    }

    private BikeMasterAdminRequest seed(
            String brand,
            String model,
            String variant,
            int engineCc,
            String category,
            String bikeType,
            double tankCapacity,
            int rangeKm,
            int comfortScore) {
        BikeMasterAdminRequest request = new BikeMasterAdminRequest();
        request.setBrand(brand);
        request.setModel(model);
        request.setVariant(variant);
        request.setEngineCc(engineCc);
        request.setCategory(category);
        request.setBikeType(bikeType);
        request.setTankCapacity(BigDecimal.valueOf(tankCapacity));
        request.setRangeKm(rangeKm);
        request.setComfortScore(comfortScore);
        request.setActive(true);
        request.setVerified(true);
        return request;
    }
}
