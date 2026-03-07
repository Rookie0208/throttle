package com.ridersclub.notification.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.notification.entity.Notification;

public interface NotificationRepository {

    Notification save(Notification notification);

    Optional<Notification> findById(Long id);

    List<Notification> findByUserUuidOrderByCreatedAtDesc(String userUuid);

    List<Notification> findAll();

}