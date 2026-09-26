package com.ridersclub.message.entity;

import java.time.LocalDateTime;

import com.ridersclub.common.enums.MessageType;
import com.ridersclub.ride.entity.RideGroup;
import com.ridersclub.user.entity.User;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "group_messages")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GroupMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, updatable = false)
    private String uuid;

    // 👤 sender
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    // 👥 group
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    private RideGroup group;

    // 💬 message text
    @Column(columnDefinition = "TEXT")
    private String message;

    // 📎 media url (image/video/file)
    private String mediaUrl;

    // message type
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private MessageType messageType;

    // reply feature (future ready)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reply_to_message_id")
    private GroupMessage replyTo;

    private LocalDateTime createdAt;

    private Boolean edited = false;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
    }
}
