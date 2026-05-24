package com.ridersclub.admin.repository;

import com.ridersclub.admin.entity.SystemResource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SystemResourceRepository extends JpaRepository<SystemResource, Long> {

    Optional<SystemResource> findByResourceKey(String resourceKey);

    List<SystemResource> findByCategory(String category);
}
