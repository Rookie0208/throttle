package com.ridersclub.auth.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentMatchers;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.ridersclub.auth.dto.request.LoginRequest;
import com.ridersclub.auth.dto.request.RegisterRequest;
import com.ridersclub.auth.dto.response.LoginResponse;
import com.ridersclub.auth.dto.response.RegisterResponse;
import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.Role;
import com.ridersclub.common.enums.UuidPrefix;
import com.ridersclub.common.exception.EmailAlreadyExistsException;
import com.ridersclub.common.exception.InvalidCredentialsException;
import com.ridersclub.auth.security.JwtService;
import com.ridersclub.bike.service.BikeRegistryService;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.service.RiderIdService;
import com.ridersclub.user.service.UserService;

class AuthServiceTest {

    @Mock
    private UserService userService;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @Mock
    private OtpService otpService;

    @Mock
    private RefreshTokenService refreshTokenService;

    @Mock
    private org.springframework.data.neo4j.core.Neo4jClient neo4jClient;

    @Mock
    private RiderIdService riderIdService;

    @Mock
    private BikeRegistryService bikeRegistryService;

    @Mock
    private com.ridersclub.admin.service.SystemResourceService resourceService;

    private AuthService authService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
        authService = new AuthService(
                userService,
                passwordEncoder,
                jwtService,
                otpService,
                refreshTokenService,
                neo4jClient,
                riderIdService,
                bikeRegistryService,
                resourceService);
    }

    @Test
    void register_success() {
        RegisterRequest req = new RegisterRequest();
        req.setEmail("test@example.com");
        req.setPassword("secret");
        req.setFirstName("John");
        req.setLastName("Doe");
        req.setRiderId("john.doe");

        when(userService.existsByEmail("test@example.com")).thenReturn(false);
        when(riderIdService.normalizeAndValidateRequested("john.doe")).thenReturn("john.doe");
        doNothing().when(riderIdService).assertAvailable("john.doe");
        when(passwordEncoder.encode("secret")).thenReturn("encoded");
        User saved = new User();
        saved.setId(1L);
        saved.setUuid(UserUtility.generateUUID(UuidPrefix.USER.name()));
        saved.setRiderId("john.doe");
        when(userService.save(ArgumentMatchers.any(User.class))).thenReturn(saved);
        when(jwtService.generate(anyString(), anyMap(), anyLong())).thenReturn("token123");

        com.ridersclub.auth.entity.RefreshToken rt = new com.ridersclub.auth.entity.RefreshToken();
        rt.setToken("refresh123");
        when(refreshTokenService.createRefreshToken(saved.getId())).thenReturn(rt);

        RegisterResponse resp = authService.register(req);
        assertNotNull(resp);
        assertEquals(saved.getUuid().toString(), resp.userId());
        assertTrue(resp.verificationRequired());
        assertEquals("token123", resp.token());
        assertEquals("refresh123", resp.refreshToken());
    }

    @Test
    void register_duplicateEmail() {
        RegisterRequest req = new RegisterRequest();
        req.setEmail("test@example.com");
        when(userService.existsByEmail("test@example.com")).thenReturn(true);
        assertThrows(EmailAlreadyExistsException.class, () -> authService.register(req));
    }

    @Test
    void login_success() {
        LoginRequest req = new LoginRequest();
        req.setEmail("a@b.com");
        req.setPassword("pwd");

        User user = new User();
        user.setId(1L);
        user.setUuid(UserUtility.generateUUID(UuidPrefix.USER.name()));
        user.setPassword("hash");
        user.setRole(Role.RIDER);
        when(userService.findByEmail("a@b.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pwd", "hash")).thenReturn(true);
        when(jwtService.generate(anyString(), anyMap(), anyLong())).thenReturn("token123");

        com.ridersclub.auth.entity.RefreshToken rt = new com.ridersclub.auth.entity.RefreshToken();
        rt.setToken("refresh123");
        when(refreshTokenService.createRefreshToken(anyLong())).thenReturn(rt);

        LoginResponse resp = authService.login(req);
        assertNotNull(resp);
        assertEquals(user.getUuid().toString(), resp.userId());
        assertEquals("token123", resp.token());
        assertEquals("refresh123", resp.refreshToken());
    }

    @Test
    void login_invalidPassword() {
        LoginRequest req = new LoginRequest();
        req.setEmail("a@b.com");
        req.setPassword("pwd");
        User user = new User();
        user.setPassword("hash");
        when(userService.findByEmail("a@b.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pwd", "hash")).thenReturn(false);
        assertThrows(InvalidCredentialsException.class, () -> authService.login(req));
    }

    @Test
    void login_userNotFound() {
        LoginRequest req = new LoginRequest();
        req.setEmail("x@y.com");
        when(userService.findByEmail("x@y.com")).thenReturn(Optional.empty());
        assertThrows(InvalidCredentialsException.class, () -> authService.login(req));
    }
}