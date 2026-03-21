package com.ridersclub.message.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ridersclub.message.entity.MessageRead;

public interface MessageReadRepository
        extends JpaRepository<MessageRead, Long> {
}