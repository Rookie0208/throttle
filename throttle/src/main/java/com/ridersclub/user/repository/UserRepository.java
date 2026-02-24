package com.ridersclub.user.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Repository;
import com.ridersclub.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

@Repository
public interface UserRepository extends JpaRepository<User, String> {
    Optional<User> findByEmail(String email);

    Optional<User> findById(int id);

    boolean existsByEmail(String email);
}