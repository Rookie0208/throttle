package com.ridersclub.user.repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Repository;

import com.ridersclub.user.entity.User;

@Repository
public class InMemoryUserRepo implements UserRepository {
    
private final Map<String, User> users = new ConcurrentHashMap<>();

    @Override
    public User save(User user) {
        if (user.getUuid() == null) {
            user.setUuid(UUID.randomUUID().toString());
        }
        users.put(user.getEmail(), user);
        return user;
    }

    @Override
    public Optional<User> findByEmail(String email) {
        return Optional.ofNullable(users.get(email));
    }

    @Override
    public Optional<User> findById(String id) {
        return users.values()
                .stream()
                .filter(u -> u.getId().equals(id))
                .findFirst();
    }

    @Override
    public List<User> findAll() {
        return new ArrayList<>(users.values());
    }

    @Override
    public boolean existsByEmail(String email) {
        return users.containsKey(email);
    }
}
