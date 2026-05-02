package com.ridersclub.bike.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.math.BigDecimal;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

import com.ridersclub.bike.dto.request.BikeMasterAdminRequest;
import com.ridersclub.bike.dto.response.BikeMasterResponse;
import com.ridersclub.bike.entity.BikeMaster;
import com.ridersclub.bike.repository.BikeMasterRepository;
import com.ridersclub.common.exception.UserNotFoundException;
import com.ridersclub.config.BackendResourceConfig;
import com.ridersclub.user.dto.request.UserBikeRequest;
import com.ridersclub.user.dto.response.UserProfileResponse;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.entity.UserBike;
import com.ridersclub.user.repository.UserBikeRepository;
import com.ridersclub.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class BikeRegistryService {
    private static final int DEFAULT_LIMIT = 25;

    private final BikeMasterRepository bikeMasterRepository;
    private final UserRepository userRepository;
    private final UserBikeRepository userBikeRepository;
    private final PlatformTransactionManager transactionManager;
    private final BackendResourceConfig backendResourceConfig;

    public int ensureSeedData() {
        TransactionTemplate seedTemplate = new TransactionTemplate(transactionManager);
        seedTemplate.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        seedTemplate.setReadOnly(false);
        Integer inserted = seedTemplate.execute(status -> seedIfEmpty(defaultSeedData()));
        return inserted == null ? 0 : inserted;
    }

    @Transactional(readOnly = true)
    public List<String> findBrands(String query) {
        ensureSeedData();
        return bikeMasterRepository.findBrands(normalizeQuery(query))
                .stream()
                .filter(value -> !isBlank(value))
                .map(String::trim)
                .distinct()
                .sorted(Comparator.naturalOrder())
                .limit(DEFAULT_LIMIT)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<String> findModels(String brand, String query) {
        ensureSeedData();
        if (isBlank(brand)) {
            return List.of();
        }
        return bikeMasterRepository.findModels(brand.trim(), normalizeQuery(query))
                .stream()
                .filter(value -> !isBlank(value))
                .map(String::trim)
                .distinct()
                .sorted(Comparator.naturalOrder())
                .limit(DEFAULT_LIMIT)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BikeMasterResponse> findVariants(String brand, String model, String query) {
        ensureSeedData();
        if (isBlank(brand) || isBlank(model)) {
            return List.of();
        }
        List<BikeMasterResponse> directMatches = bikeMasterRepository.findVariants(brand.trim(), model.trim(), normalizeQuery(query))
                .stream()
                .limit(DEFAULT_LIMIT)
                .map(BikeMasterResponse::from)
                .toList();
        if (!directMatches.isEmpty()) {
            return directMatches;
        }

        String normalizedBrand = normalizeLookupValue(brand);
        String normalizedModel = normalizeLookupValue(model);
        String searchTerm = buildVariantSearchTerm(brand, model, query);

        return bikeMasterRepository.searchActive(searchTerm)
                .stream()
                .filter(item -> normalizeLookupValue(item.getBrand()).equals(normalizedBrand))
                .filter(item -> normalizeLookupValue(item.getModel()).equals(normalizedModel))
                .filter(item -> matchesVariantQuery(item.getVariant(), query))
                .limit(DEFAULT_LIMIT)
                .map(BikeMasterResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BikeMasterResponse> search(String query) {
        ensureSeedData();
        return bikeMasterRepository.searchActive(normalizeQuery(query))
                .stream()
                .limit(DEFAULT_LIMIT)
                .map(BikeMasterResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BikeMasterResponse> adminSearch(String query) {
        ensureSeedData();
        return bikeMasterRepository.searchAll(normalizeQuery(query))
                .stream()
                .limit(100)
                .map(BikeMasterResponse::from)
                .toList();
    }

    public BikeMasterResponse createBike(BikeMasterAdminRequest request) {
        validateCategory(request.getCategory());
        if (bikeMasterRepository.existsByBrandIgnoreCaseAndModelIgnoreCaseAndVariantIgnoreCase(
                request.getBrand().trim(),
                request.getModel().trim(),
                request.getVariant().trim())) {
            throw new IllegalArgumentException("Bike already exists for this brand, model, and variant");
        }

        BikeMaster bike = toEntity(new BikeMaster(), request);
        bike.setActive(request.getActive() == null || request.getActive());
        bike.setVerified(request.getVerified() == null || request.getVerified());
        return BikeMasterResponse.from(bikeMasterRepository.save(bike));
    }

    public BikeMasterResponse updateBike(Long id, BikeMasterAdminRequest request) {
        validateCategory(request.getCategory());
        BikeMaster bike = bikeMasterRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Bike master entry not found"));

        boolean duplicate = bikeMasterRepository.existsByBrandIgnoreCaseAndModelIgnoreCaseAndVariantIgnoreCase(
                request.getBrand().trim(),
                request.getModel().trim(),
                request.getVariant().trim());
        boolean changedIdentity = !bike.getBrand().equalsIgnoreCase(request.getBrand().trim())
                || !bike.getModel().equalsIgnoreCase(request.getModel().trim())
                || !bike.getVariant().equalsIgnoreCase(request.getVariant().trim());
        if (duplicate && changedIdentity) {
            throw new IllegalArgumentException("Bike already exists for this brand, model, and variant");
        }

        return BikeMasterResponse.from(bikeMasterRepository.save(toEntity(bike, request)));
    }

    public BikeMasterResponse verifyBike(Long id) {
        BikeMaster bike = bikeMasterRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Bike master entry not found"));
        bike.setVerified(true);
        bike.setActive(true);
        return BikeMasterResponse.from(bikeMasterRepository.save(bike));
    }

    public BikeMasterResponse deactivateBike(Long id) {
        BikeMaster bike = bikeMasterRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Bike master entry not found"));
        bike.setActive(false);
        return BikeMasterResponse.from(bikeMasterRepository.save(bike));
    }

    public UserProfileResponse.UserBikeDto addUserBike(String userUuid, UserBikeRequest request) {
        User user = userRepository.findByUuid(userUuid)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        validateBikeLimit(user);

        boolean makePrimary = Boolean.TRUE.equals(request.getPrimary())
                || userBikeRepository.countByUserId(user.getId()) == 0;
        if (makePrimary) {
            clearPrimaryBike(user.getId());
        }

        UserBike bike = new UserBike();
        bike.setUser(user);
        bike.setYear(request.getYear());
        bike.setPrimary(makePrimary);

        if (request.getBikeMasterId() != null) {
            BikeMaster master = bikeMasterRepository.findByIdAndActiveTrue(request.getBikeMasterId())
                    .orElseThrow(() -> new IllegalArgumentException("Selected bike is not available"));
            applyMasterSnapshot(bike, master);
        } else {
            validateCustomBike(request);
            bike.setMake(request.getBrand().trim());
            bike.setModel(request.getModel().trim());
            bike.setVariant(request.getVariant().trim());
            bike.setEngineCc(request.getEngineCc());
            bike.setCategory(normalizeCategory(request.getCategory()));
            bike.setType(request.getBikeType().trim());
            bike.setTankCapacity(request.getTankCapacity());
            bike.setRangeKm(request.getRangeKm());
            bike.setComfortScore(request.getComfortScore());
            bike.setVerified(false);
        }

        UserBike savedBike = userBikeRepository.save(bike);
        if ((user.getBikeType() == null || user.getBikeType().isBlank()) && savedBike.getType() != null) {
            user.setBikeType(savedBike.getType());
            userRepository.save(user);
        }
        return mapUserBike(savedBike);
    }

    public void registerInitialBike(User user, UserBikeRequest request) {
        if (user == null || request == null) {
            return;
        }
        if (request.getBikeMasterId() == null
                && (isBlank(request.getBrand()) || isBlank(request.getModel()) || isBlank(request.getVariant()))) {
            return;
        }
        addUserBike(user.getUuid(), request.withPrimary(true));
    }

    public void removeUserBike(String userUuid, Long bikeId) {
        User user = userRepository.findByUuid(userUuid)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        UserBike bike = userBikeRepository.findByIdAndUserId(bikeId, user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Bike not found"));

        boolean wasPrimary = bike.isPrimary();
        userBikeRepository.delete(bike);

        if (wasPrimary) {
            userBikeRepository.findByUserIdOrderByPrimaryDescCreatedAtAsc(user.getId())
                    .stream()
                    .findFirst()
                    .ifPresent(nextBike -> {
                        nextBike.setPrimary(true);
                        userBikeRepository.save(nextBike);
                    });
        }
    }

    public UserProfileResponse.UserBikeDto mapUserBike(UserBike bike) {
        String bikeType = bike.getType() == null ? "" : bike.getType();
        return new UserProfileResponse.UserBikeDto(
                bike.getId(),
                bike.getBikeMaster() != null ? bike.getBikeMaster().getId() : null,
                bike.getMake(),
                bike.getMake(),
                bike.getModel(),
                bike.getVariant(),
                bike.getYear(),
                bikeType,
                bike.getCategory(),
                bikeType,
                bike.getEngineCc(),
                bike.getTankCapacity(),
                bike.getRangeKm(),
                bike.getComfortScore(),
                bike.isPrimary(),
                bike.isVerified());
    }

    public int seedIfEmpty(List<BikeMasterAdminRequest> bikes) {
        if (bikeMasterRepository.count() > 0) {
            return 0;
        }
        List<BikeMaster> entities = bikes.stream()
                .map(request -> toEntity(new BikeMaster(), request))
                .peek(bike -> {
                    bike.setActive(true);
                    bike.setVerified(true);
                })
                .toList();
        bikeMasterRepository.saveAll(entities);
        return entities.size();
    }

    public int importCatalog(List<BikeMasterAdminRequest> bikes) {
        List<BikeMaster> toSave = new ArrayList<>();
        Set<String> seen = new LinkedHashSet<>();

        for (BikeMasterAdminRequest request : bikes) {
            if (isBlank(request.getBrand()) || isBlank(request.getModel()) || isBlank(request.getVariant())) {
                continue;
            }
            String key = (request.getBrand() + "|" + request.getModel() + "|" + request.getVariant())
                    .toLowerCase(Locale.ENGLISH);
            if (seen.contains(key)
                    || bikeMasterRepository.existsByBrandIgnoreCaseAndModelIgnoreCaseAndVariantIgnoreCase(
                            request.getBrand().trim(),
                            request.getModel().trim(),
                            request.getVariant().trim())) {
                continue;
            }
            seen.add(key);
            BikeMaster bike = toEntity(new BikeMaster(), request);
            bike.setActive(true);
            bike.setVerified(true);
            toSave.add(bike);
        }

        if (!toSave.isEmpty()) {
            bikeMasterRepository.saveAll(toSave);
        }
        return toSave.size();
    }

    private BikeMaster toEntity(BikeMaster bike, BikeMasterAdminRequest request) {
        bike.setBrand(request.getBrand().trim());
        bike.setModel(request.getModel().trim());
        bike.setVariant(request.getVariant().trim());
        bike.setEngineCc(request.getEngineCc());
        bike.setCategory(normalizeCategory(request.getCategory()));
        bike.setBikeType(request.getBikeType().trim());
        bike.setTankCapacity(request.getTankCapacity());
        bike.setRangeKm(request.getRangeKm());
        bike.setComfortScore(request.getComfortScore());
        if (request.getActive() != null) {
            bike.setActive(request.getActive());
        }
        if (request.getVerified() != null) {
            bike.setVerified(request.getVerified());
        }
        return bike;
    }

    private void applyMasterSnapshot(UserBike bike, BikeMaster master) {
        bike.setBikeMaster(master);
        bike.setMake(master.getBrand());
        bike.setModel(master.getModel());
        bike.setVariant(master.getVariant());
        bike.setEngineCc(master.getEngineCc());
        bike.setCategory(master.getCategory());
        bike.setType(master.getBikeType());
        bike.setTankCapacity(master.getTankCapacity());
        bike.setRangeKm(master.getRangeKm());
        bike.setComfortScore(master.getComfortScore());
        bike.setVerified(master.isVerified());
    }

    private void validateCustomBike(UserBikeRequest request) {
        if (isBlank(request.getBrand())
                || isBlank(request.getModel())
                || isBlank(request.getVariant())
                || request.getEngineCc() == null
                || isBlank(request.getCategory())
                || isBlank(request.getBikeType())) {
            throw new IllegalArgumentException(
                    "Custom bike requires brand, model, variant, engine CC, category, and bike type");
        }
        validateCategory(request.getCategory());
    }

    private void validateBikeLimit(User user) {
        long bikeCount = userBikeRepository.countByUserId(user.getId());
        int freePlanMaxBikes = backendResourceConfig.getSubscription().getFreePlanMaxBikes();
        if (!user.isSubscriptionActive() && bikeCount >= freePlanMaxBikes) {
            throw new IllegalArgumentException(
                    "You can add up to " + freePlanMaxBikes
                            + " bikes on the free plan. Remove an existing bike or upgrade your subscription.");
        }
    }

    private void clearPrimaryBike(Long userId) {
        List<UserBike> bikes = userBikeRepository.findByUserId(userId);
        for (UserBike bike : bikes) {
            if (bike.isPrimary()) {
                bike.setPrimary(false);
            }
        }
        if (!bikes.isEmpty()) {
            userBikeRepository.saveAll(bikes);
        }
    }

    private String normalizeCategory(String value) {
        String normalized = value.trim().toLowerCase(Locale.ENGLISH);
        if ("adv".equals(normalized)) {
            return "adv";
        }
        return normalized;
    }

    private void validateCategory(String value) {
        String normalized = normalizeCategory(value);
        if (!List.of("cruiser", "sport", "commuter", "adv").contains(normalized)) {
            throw new IllegalArgumentException("Category must be one of cruiser, sport, commuter, or ADV");
        }
    }

    private String normalizeQuery(String query) {
        return query == null ? "" : query.trim();
    }

    private String normalizeLookupValue(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().replaceAll("\\s+", " ").toLowerCase(Locale.ENGLISH);
    }

    private String buildVariantSearchTerm(String brand, String model, String query) {
        StringBuilder builder = new StringBuilder();
        if (!isBlank(brand)) {
            builder.append(brand.trim());
        }
        if (!isBlank(model)) {
            if (builder.length() > 0) {
                builder.append(' ');
            }
            builder.append(model.trim());
        }
        if (!isBlank(query)) {
            if (builder.length() > 0) {
                builder.append(' ');
            }
            builder.append(query.trim());
        }
        return builder.toString();
    }

    private boolean matchesVariantQuery(String variant, String query) {
        if (isBlank(query)) {
            return true;
        }
        return normalizeLookupValue(variant).contains(normalizeLookupValue(query));
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private List<BikeMasterAdminRequest> defaultSeedData() {
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
