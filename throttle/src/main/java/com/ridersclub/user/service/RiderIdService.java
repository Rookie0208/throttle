package com.ridersclub.user.service;

import java.text.Normalizer;
import java.util.Locale;
import java.util.regex.Pattern;

import org.springframework.stereotype.Service;

import com.ridersclub.common.exception.RiderIdAlreadyExistsException;
import com.ridersclub.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class RiderIdService {

    private static final int MIN_LENGTH = 3;
    private static final int MAX_LENGTH = 30;
    private static final Pattern VALID_RIDER_ID = Pattern.compile("^[a-z0-9._]{3,30}$");
    private static final Pattern NON_ASCII_MARKS = Pattern.compile("\\p{M}+");
    private static final Pattern INVALID_CHARS = Pattern.compile("[^a-z0-9._]+");
    private static final Pattern DUPLICATE_SEPARATORS = Pattern.compile("[._]{2,}");
    private static final Pattern EDGE_SEPARATORS = Pattern.compile("^[._]+|[._]+$");

    private final UserRepository userRepository;

    public String normalizeAndValidateRequested(String riderId) {
        String normalized = normalize(riderId);
        if (normalized.isBlank()) {
            throw new IllegalArgumentException("Rider ID is required");
        }
        if (!VALID_RIDER_ID.matcher(normalized).matches()) {
            throw new IllegalArgumentException(
                    "Rider ID must be 3-30 characters and use only letters, numbers, dots, or underscores");
        }
        return normalized;
    }

    public void assertAvailable(String riderId) {
        if (userRepository.existsByRiderId(riderId)) {
            throw new RiderIdAlreadyExistsException("Rider ID is already taken");
        }
    }

    public String generateUniqueRiderId(String firstName, String lastName) {
        String base = sanitizeBase(firstName, lastName);
        if (base.length() < MIN_LENGTH) {
            base = (base + "rider");
        }
        if (base.length() > MAX_LENGTH) {
            base = base.substring(0, MAX_LENGTH);
        }

        String candidate = base;
        int suffix = 1;
        while (userRepository.existsByRiderId(candidate)) {
            String suffixText = String.valueOf(suffix++);
            int maxBaseLength = MAX_LENGTH - suffixText.length();
            String truncatedBase = base.substring(0, Math.min(base.length(), Math.max(MIN_LENGTH, maxBaseLength)));
            candidate = truncatedBase + suffixText;
        }
        return candidate;
    }

    public String normalize(String riderId) {
        if (riderId == null) {
            return "";
        }
        String trimmed = riderId.trim().toLowerCase(Locale.ROOT);
        if (trimmed.isEmpty()) {
            return "";
        }

        String normalized = Normalizer.normalize(trimmed, Normalizer.Form.NFD);
        normalized = NON_ASCII_MARKS.matcher(normalized).replaceAll("");
        normalized = INVALID_CHARS.matcher(normalized).replaceAll("_");
        normalized = DUPLICATE_SEPARATORS.matcher(normalized).replaceAll("_");
        normalized = EDGE_SEPARATORS.matcher(normalized).replaceAll("");

        if (normalized.length() > MAX_LENGTH) {
            normalized = normalized.substring(0, MAX_LENGTH);
            normalized = EDGE_SEPARATORS.matcher(normalized).replaceAll("");
        }
        return normalized;
    }

    private String sanitizeBase(String firstName, String lastName) {
        StringBuilder candidate = new StringBuilder();
        if (firstName != null && !firstName.isBlank()) {
            candidate.append(firstName);
        }
        if (lastName != null && !lastName.isBlank()) {
            if (candidate.length() > 0) {
                candidate.append('.');
            }
            candidate.append(lastName);
        }
        String normalized = normalize(candidate.toString());
        return normalized.isBlank() ? "rider" : normalized;
    }
}
