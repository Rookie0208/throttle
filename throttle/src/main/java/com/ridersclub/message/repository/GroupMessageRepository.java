package com.ridersclub.message.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ridersclub.message.entity.GroupMessage;

public interface GroupMessageRepository
        extends JpaRepository<GroupMessage, Long> {

    List<GroupMessage> findTop20ByGroup_UuidOrderByCreatedAtDesc(String groupUuid);
}