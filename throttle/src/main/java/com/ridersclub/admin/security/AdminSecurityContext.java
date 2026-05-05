package com.ridersclub.admin.security;

import com.ridersclub.common.exception.UserNotFoundException;
import com.ridersclub.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/**
 * AdminSecurityContext
 *
 * Centralises the extraction of the authenticated admin's numeric database ID
 * from the JWT Security Context. The JWT subject is the user's UUID (string);
 * this helper resolves it to the Long PK required by audit and domain operations.
 *
 * Why a separate component?
 *   - Keeps AdminController and AdminService free of SecurityContext coupling.
 *   - Single place to change if the principal strategy ever changes.
 *   - Mockable in unit tests.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminSecurityContext {

    private final UserRepository userRepository;

    /**
     * Returns the numeric database ID of the currently authenticated admin.
     *
     * @throws IllegalStateException  if no authentication is present in the context
     * @throws UserNotFoundException  if the UUID in the token does not match any user
     */
    public Long getCurrentAdminId() {
        Object principal = SecurityContextHolder.getContext()
                .getAuthentication()
                .getPrincipal();

        if (principal == null || "anonymousUser".equals(principal)) {
            throw new IllegalStateException("No authenticated admin in security context");
        }

        String uuid = principal.toString();
        log.debug("Resolving admin ID for UUID={}", uuid);

        return userRepository.findByUuid(uuid)
                .map(user -> user.getId())
                .orElseThrow(() -> new UserNotFoundException("Admin user not found for UUID: " + uuid));
    }
}
