package com.ridersclub.message.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.message.entity.MessageRead;

@Repository
public interface MessageReadRepository
                extends JpaRepository<MessageRead, Long> {
}