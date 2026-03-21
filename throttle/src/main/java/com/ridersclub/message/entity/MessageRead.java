package com.ridersclub.message.entity;

import java.time.LocalDateTime;

import com.ridersclub.user.entity.User;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "message_reads", uniqueConstraints = @UniqueConstraint(columnNames = { "message_id", "user_id" }))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MessageRead {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "message_id", nullable = false)
    private GroupMessage message;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private LocalDateTime readAt;

    @PrePersist
    public void prePersist() {
        this.readAt = LocalDateTime.now();
    }
}