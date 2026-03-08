package com.ridersclub.notification.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.notification.entity.Notifications;

@Repository
public interface NotificationRepository extends JpaRepository<Notifications, Long> {

List<Notifications> findByUserIdOrderByCreatedAtDesc(Long userId);
    // List<Notification> findByUserUuidOrderByCreatedAtDesc(String userUuid);

}