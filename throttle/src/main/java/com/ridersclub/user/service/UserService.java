package com.ridersclub.user.service;

import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ridersclub.user.dto.request.UpdateProfileRequest;
import com.ridersclub.user.dto.response.UserProfileResponse;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;


    // --- helper methods used by other services ---
    public java.util.Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }

    public User save(User user) {
        return userRepository.save(user);
    }

    public User getUserByUuid(UUID uuid) {
        return userRepository.findByUuid(uuid)
                .orElseThrow(() -> new com.ridersclub.common.exception.UserNotFoundException("User not found"));
    }

    public UserProfileResponse getProfile(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new com.ridersclub.common.exception.UserNotFoundException("User not found"));
        return new UserProfileResponse(user);
    }

    public UserProfileResponse getProfileByUUID(String uuidStr) {
        User user = userRepository.findByUuid(UUID.fromString(uuidStr))
                .orElseThrow(() -> new com.ridersclub.common.exception.UserNotFoundException("User not found"));
        return new UserProfileResponse(user);
    }

    public UserProfileResponse updateProfile(
            String userId,
            UpdateProfileRequest request
    ) {

        User user = userRepository.findById(Long.valueOf(userId))
                .orElseThrow(() -> new com.ridersclub.common.exception.UserNotFoundException("User not found"));

        // Update only non-null fields
        if (request.getFirstName() != null)
            user.setFirstName(request.getFirstName());

        if (request.getLastName() != null)
            user.setLastName(request.getLastName());

        if (request.getBio() != null)
            user.setBio(request.getBio());

        if (request.getProfileImage() != null)
            user.setProfileImage(request.getProfileImage());

        userRepository.save(user);

        return new UserProfileResponse(user);
    }

}
