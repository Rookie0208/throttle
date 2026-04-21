package com.ridersclub.bike.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.bike.dto.request.BikeMasterAdminRequest;
import com.ridersclub.bike.dto.response.BikeMasterResponse;
import com.ridersclub.bike.entity.BikeMaster;
import com.ridersclub.bike.repository.BikeMasterRepository;
import com.ridersclub.common.exception.UserNotFoundException;
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
    private static final int FREE_PLAN_BIKE_LIMIT = 3;
    private static final int DEFAULT_LIMIT = 25;

    private final BikeMasterRepository bikeMasterRepository;
    private final UserRepository userRepository;
    private final UserBikeRepository userBikeRepository;

    @Transactional(readOnly = true)
    @Cacheable(value = "bike_brands", key = "#root.methodName + ':' + (#query == null ? '' : #query.trim().toLowerCase())")
    public List<String> findBrands(String query) {
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
    @Cacheable(value = "bike_models", key = "#root.methodName + ':' + #brand.trim().toLowerCase() + ':' + (#query == null ? '' : #query.trim().toLowerCase())")
    public List<String> findModels(String brand, String query) {
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
    @Cacheable(value = "bike_variants", key = "#root.methodName + ':' + #brand.trim().toLowerCase() + ':' + #model.trim().toLowerCase() + ':' + (#query == null ? '' : #query.trim().toLowerCase())")
    public List<BikeMasterResponse> findVariants(String brand, String model, String query) {
        if (isBlank(brand) || isBlank(model)) {
            return List.of();
        }
        return bikeMasterRepository.findVariants(brand.trim(), model.trim(), normalizeQuery(query))
                .stream()
                .limit(DEFAULT_LIMIT)
                .map(BikeMasterResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "bike_search", key = "#root.methodName + ':' + (#query == null ? '' : #query.trim().toLowerCase())")
    public List<BikeMasterResponse> search(String query) {
        return bikeMasterRepository.searchActive(normalizeQuery(query))
                .stream()
                .limit(DEFAULT_LIMIT)
                .map(BikeMasterResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BikeMasterResponse> adminSearch(String query) {
        return bikeMasterRepository.searchAll(normalizeQuery(query))
                .stream()
                .limit(100)
                .map(BikeMasterResponse::from)
                .toList();
    }

    @CacheEvict(value = { "bike_brands", "bike_models", "bike_variants", "bike_search" }, allEntries = true)
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

    @CacheEvict(value = { "bike_brands", "bike_models", "bike_variants", "bike_search" }, allEntries = true)
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

    @CacheEvict(value = { "bike_brands", "bike_models", "bike_variants", "bike_search" }, allEntries = true)
    public BikeMasterResponse verifyBike(Long id) {
        BikeMaster bike = bikeMasterRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Bike master entry not found"));
        bike.setVerified(true);
        bike.setActive(true);
        return BikeMasterResponse.from(bikeMasterRepository.save(bike));
    }

    @CacheEvict(value = { "bike_brands", "bike_models", "bike_variants", "bike_search" }, allEntries = true)
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

    @CacheEvict(value = { "bike_brands", "bike_models", "bike_variants", "bike_search" }, allEntries = true)
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

    @CacheEvict(value = { "bike_brands", "bike_models", "bike_variants", "bike_search" }, allEntries = true)
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
        if (!user.isSubscriptionActive() && bikeCount >= FREE_PLAN_BIKE_LIMIT) {
            throw new IllegalArgumentException(
                    "You can add up to 3 bikes on the free plan. Remove an existing bike or upgrade your subscription.");
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

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
