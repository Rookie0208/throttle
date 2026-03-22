package com.ridersclub.auth.service;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.auth.entity.RefreshToken;
import com.ridersclub.auth.repository.RefreshTokenRepository;
import com.ridersclub.user.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class RefreshTokenService {
    // 30 days
    private final long refreshTokenDurationMs = 2592000000L;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    @Autowired
    private UserRepository userRepository;

    public Optional<RefreshToken> findByToken(String token) {
        return refreshTokenRepository.findByToken(token);
    }

    public RefreshToken createRefreshToken(Long userId) {
        log.debug("Creating new refresh token for userId: {}", userId);
        RefreshToken refreshToken = new RefreshToken();

        refreshToken.setUser(userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found")));
        refreshToken.setExpiryDate(Instant.now().plusMillis(refreshTokenDurationMs));
        refreshToken.setToken(UUID.randomUUID().toString());

        RefreshToken savedToken = refreshTokenRepository.save(refreshToken);
        log.info("Successfully created and saved refresh token for userId: {}", userId);
        return savedToken;
    }

    public RefreshToken verifyExpiration(RefreshToken token) {
        if (token.getExpiryDate().compareTo(Instant.now()) < 0) {
            log.warn("Refresh token expired for userId: {}", token.getUser().getId());
            refreshTokenRepository.delete(token);
            throw new RuntimeException("Refresh token was expired. Please make a new sign in request");
        }
        log.debug("Refresh token verified successfully");
        return token;
    }
    
    @Transactional
    public void deleteByUserId(Long userId) {
        log.debug("Deleting all refresh tokens for userId: {}", userId);
        userRepository.findById(userId).ifPresent(user -> refreshTokenRepository.deleteByUser(user));
    }
    
    @Transactional
    public void deleteByToken(RefreshToken token) {
        log.debug("Deleting specific refresh token from database");
        refreshTokenRepository.delete(token);
    }
}
