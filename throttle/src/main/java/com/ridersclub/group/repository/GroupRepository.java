package com.ridersclub.group.repository;

import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.ridersclub.group.entity.Group;

@Repository
public interface GroupRepository extends org.springframework.data.repository.Repository<Group, Long> {

    Group save(Group group);

    Optional<Group> findById(Long groupId);

}
