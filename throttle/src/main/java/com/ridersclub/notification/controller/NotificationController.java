package com.ridersclub.notification.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.notification.entity.Notification;
import com.ridersclub.notification.repository.NotificationRepository;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    @Autowired
    private NotificationRepository notificationRepository;

    @GetMapping("/notifications")
public List<Notification> myNotifications(@RequestParam String userUuid) {
    return notificationRepository.findByUserUuidOrderByCreatedAtDesc(userUuid);
}

    // @GetMapping("/my")
    // public List<Notification> myNotifications(@AuthenticationPrincipal UserDetails user) {
    //     return notificationRepository.findByUser_UuidOrderByCreatedAtDesc(user.getUsername());
    // }

    @GetMapping("/my")
    public List<Notification> myNotifications(Authentication authentication) {

        String userUuid = authentication.getName();

        return notificationRepository
                .findByUserUuidOrderByCreatedAtDesc(userUuid);
    }

    @PostMapping("/{id}/read")
    public void markAsRead(@PathVariable Long id) {
        Notification notif = notificationRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Notification not found"));
        notif.setRead(true);
        notificationRepository.save(notif);
    }
}
