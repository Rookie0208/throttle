package com.ridersclub.admin.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ridersclub.admin.entity.FrontendResourceConfigEntity;

public interface FrontendResourceConfigRepository extends JpaRepository<FrontendResourceConfigEntity, Long> {
    Optional<FrontendResourceConfigEntity> findByResourceKey(String resourceKey);
}
