package com.ridersclub.message.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ridersclub.common.enums.MessageType;
import com.ridersclub.message.entity.GroupMessage;

@Repository
public interface GroupMessageRepository
        extends JpaRepository<GroupMessage, Long> {

    List<GroupMessage> findTop20ByGroup_UuidOrderByCreatedAtDesc(String groupUuid);

    List<GroupMessage> findByGroup_IdAndMessageTypeOrderByCreatedAtAsc(Long groupId, MessageType messageType);
}
