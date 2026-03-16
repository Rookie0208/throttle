package com.ridersclub.notification.controller;

import java.util.List;

import org.apache.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
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
import com.ridersclub.user.entity.User;

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
public ResponseEntity<ApiResponse<List<Notifications>>> getMyNotifications(Authentication authentication) {
    System.out.println(authentication.getPrincipal().getClass());

    User user = (User) authentication.getPrincipal();
    System.out.println("Fetching notifications for user: " + user.getEmail());
    List<Notifications> notifications = notificationService.getUserNotifications(user.getId());
    return ResponseEntity.status(org.springframework.http.HttpStatus.OK).body(ApiResponse.success(notifications, "Notifications fetched successfully"));
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
