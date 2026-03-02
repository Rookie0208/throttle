package com.ridersclub.group.repository;

import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.ridersclub.group.entity.Group;

@Repository
public class InMemoryGroupRepository implements GroupRepository {

    @Override
    public Group save(Group group) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'save'");
    }

    @Override
    public Optional<Group> findById(Long groupId) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'findById'");
    }

}
