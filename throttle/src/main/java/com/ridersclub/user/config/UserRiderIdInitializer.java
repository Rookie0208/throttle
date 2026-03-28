package com.ridersclub.user.config;

import java.util.List;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;
import com.ridersclub.user.service.RiderIdService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class UserRiderIdInitializer {

    private final UserRepository userRepository;
    private final RiderIdService riderIdService;

    @EventListener(ApplicationReadyEvent.class)
    @Transactional
    public void backfillMissingRiderIds() {
        List<User> users = userRepository.findAll();
        int updatedCount = 0;

        for (User user : users) {
            if (user.getRiderId() != null && !user.getRiderId().isBlank()) {
                continue;
            }
            user.setRiderId(riderIdService.generateUniqueRiderId(user.getFirstName(), user.getLastName()));
            userRepository.save(user);
            updatedCount++;
        }

        if (updatedCount > 0) {
            log.info("USER_INIT action=backfill_rider_ids updatedUsers={}", updatedCount);
        } else {
            log.info("USER_INIT action=backfill_rider_ids updatedUsers=0");
        }
    }
}
