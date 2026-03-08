package com.ridersclub.notification.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.common.Utils.ApiConstants;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.notification.entity.Notifications;
import com.ridersclub.notification.service.NotificationService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping(ApiConstants.Notifications.BASE)
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    /**
     * Get notifications for logged-in user
     */
    @GetMapping(ApiConstants.Notifications.MY)
    public List<Notifications> getMyNotifications(
            @AuthenticationPrincipal UserDetails userDetails) {

        Long userId = Long.parseLong(userDetails.getUsername());
        return notificationService.getUserNotifications(userId);
    }

    /**
     * Mark notification as read
     */
    @PatchMapping(ApiConstants.Notifications.MARK_AS_READ)
    public ResponseEntity<ApiResponse<Notifications>> markAsRead(@PathVariable Long id) {

        notificationService.markAsRead(id);

        return ResponseEntity.ok().build();
    }

}
