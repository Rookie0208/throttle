package com.ridersclub.notification.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.common.Utils.ApiConstants;
import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.notification.dto.NotificationResponse;
import com.ridersclub.notification.entity.Notifications;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;


@RestController
@RequestMapping(ApiConstants.Notifications.BASE)
public class NotificationController {

   private final NotificationService notificationService;
    private final UserRepository userRepository;

    public NotificationController(
            NotificationService notificationService,
            UserRepository userRepository) {
        this.notificationService = notificationService;
        this.userRepository = userRepository;
    }

    /**
     * Get notifications for logged-in user
     */
  @GetMapping(ApiConstants.Notifications.MY)
public ResponseEntity<ApiResponse<List<NotificationResponse>>> getMyNotifications(Authentication authentication) {
    System.out.println(authentication.getPrincipal().getClass());

    String userUuid = (String) authentication.getPrincipal();
    System.out.println("Authenticated user UUID: " + userUuid);
    User user = userRepository.findByUuid(userUuid)
                .orElseThrow(() -> new RuntimeException("User not found"));

    System.out.println("Fetching notifications for user: " + user.getEmail());
    List<NotificationResponse> notifications = notificationService.getMyNotifications(user.getId());
    return ResponseEntity.status(HttpStatus.OK).body(ApiResponse.success(notifications, "Notifications fetched successfully"));
}

    /**
     * Mark notification as read
     */
    @PutMapping(ApiConstants.Notifications.MARK_AS_READ)
public ResponseEntity<ApiResponse<Notifications>> updateReadStatus(
        @PathVariable Long id,
        @RequestBody Map<String, Boolean> request,
        Authentication authentication) {

    String userUuid = (String) authentication.getPrincipal();

    User user = userRepository.findByUuid(userUuid)
            .orElseThrow(() -> new RuntimeException("User not found"));

    Boolean read = request.get("read");
    if (read == null) {
        throw new RuntimeException("read field is required");
    }

    Notifications notification = notificationService.updateReadStatus(id, user.getId(), read);

    return ResponseEntity.ok(ApiResponse.success(notification, 
            read ? "Notification marked as read" : "Notification marked as unread"));
}

    @PostMapping("/read-all")
    public ResponseEntity<ApiResponse<?>> markAllAsRead(Authentication authentication) {
        String userUuid = (String) authentication.getPrincipal();

        User user = userRepository.findByUuid(userUuid)
                .orElseThrow(() -> new RuntimeException("User not found"));

        notificationService.markAllAsRead(user.getId());
        return ResponseEntity.status(HttpStatus.OK).body(ApiResponse.success(null, "All notifications marked as read"));
    }

}
