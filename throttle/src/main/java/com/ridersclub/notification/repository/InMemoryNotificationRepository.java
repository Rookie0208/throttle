package com.ridersclub.notification.repository;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Repository;

import com.ridersclub.notification.entity.Notification;

@Repository
@Primary
public class InMemoryNotificationRepository implements NotificationRepository {

    private final Map<Long, Notification> storage = new ConcurrentHashMap<>();
    private final AtomicLong idGenerator = new AtomicLong(1);

    @Override
    public Notification save(Notification notification) {

        if (notification.getId() == null) {
            notification.setId(idGenerator.getAndIncrement());
        }

        storage.put(notification.getId(), notification);
        return notification;
    }

    @Override
    public Optional<Notification> findById(Long id) {
        return Optional.ofNullable(storage.get(id));
    }

    @Override
    public List<Notification> findAll() {
        return new ArrayList<>(storage.values());
    }

    @Override
    public List<Notification> findByUserUuidOrderByCreatedAtDesc(String userUuid) {

        return storage.values()
                .stream()
                .filter(n -> n.getUser().getUuid().equals(userUuid))
                .sorted(Comparator.comparing(Notification::getCreatedAt).reversed())
                .collect(Collectors.toList());
    }
}
