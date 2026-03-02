package com.ridersclub.user.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import com.ridersclub.common.exception.UserNotFoundException;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    private UserService userService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
        userService = new UserService();
        // manually inject repository since field is autowired
        java.lang.reflect.Field field;
        try {
            field = UserService.class.getDeclaredField("userRepository");
            field.setAccessible(true);
            field.set(userService, userRepository);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Test
    void findByEmail_returnsOptional() {
        User user = new User();
        when(userRepository.findByEmail("a@b.com")).thenReturn(Optional.of(user));
        Optional<User> out = userService.findByEmail("a@b.com");
        assertTrue(out.isPresent());
    }

    @Test
    void existsByEmail_delegate() {
        when(userRepository.existsByEmail("x")).thenReturn(true);
        assertTrue(userService.existsByEmail("x"));
    }

    @Test
    void getProfileByUUID_missing() {
        when(userRepository.findByUuid(any())).thenReturn(Optional.empty());
        assertThrows(UserNotFoundException.class, () -> userService.getProfileByUUID(UUID.randomUUID().toString()));
    }
}
