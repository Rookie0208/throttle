package com.ridersclub.user.service;

import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;

import com.ridersclub.auth.dto.request.LoginRequest;
import com.ridersclub.auth.dto.request.RegisterRequest;
import com.ridersclub.common.enums.Gender;
import com.ridersclub.common.enums.Role;
import com.ridersclub.user.dto.request.UpdateProfileRequest;
import com.ridersclub.user.dto.response.UserProfileResponse;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder encoder;

    public User register(RegisterRequest req) {

        if (userRepository.findByEmail(req.getEmail()).isPresent()) {
            throw new RuntimeException("Email already exists");
        }

        User user = new User();
        user.setFirstName(req.getFirstName());
        user.setLastName(req.getLastName());
        user.setEmail(req.getEmail());
        user.setPassword(encoder.encode(req.getPassword()));
        user.setCity(req.getCity());
        user.setBikeType(req.getBikeType());
        user.setExperienceYears(req.getExperienceYears());
        user.setUuid(UUID.randomUUID());
        user.setRole(req.getRole() != null ? req.getRole() : Role.RIDER);
        user.setGender(getGenderFromPronoun(req.getPronoun()));

        return userRepository.save(user);
    }

    private Gender getGenderFromPronoun(String pronoun) {
        if (pronoun == null) {
            return Gender.MALE;
        }
        switch (pronoun.toLowerCase()) {
            case "he/him":
            case "he_him":
                return Gender.MALE;
            case "she/her":
            case "she_her":
                return Gender.FEMALE;
            default:
                return Gender.MALE;
        }
    }

    public User authenticate(LoginRequest req) {

        User user = userRepository.findByEmail(req.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid email"));

        if (!encoder.matches(req.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid password");
        }

        return user;
    }

    public UserProfileResponse getProfile(String userId) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return new UserProfileResponse(user);
    }

    public UserProfileResponse updateProfile(
            String userId,
            UpdateProfileRequest request
    ) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

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
