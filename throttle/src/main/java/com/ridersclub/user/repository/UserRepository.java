package com.ridersclub.user.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.ridersclub.user.entity.User;

@Repository
public interface UserRepository extends org.springframework.data.repository.Repository<User, String> {
    public Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    public User save(User newUser);

    Optional<User> findById(String id);

    List<User> findAll();
}