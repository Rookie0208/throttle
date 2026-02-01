package com.ridersclub.user.repository;

import java.util.Optional;

import com.ridersclub.user.entity.User;

public interface UserRepository extends org.springframework.data.repository.Repository<User, String> {
    public Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    public void save(User newUser);
}