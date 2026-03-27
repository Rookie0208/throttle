package com.ridersclub.friend.repository;

import com.ridersclub.friend.entity.FriendRequest;
import com.ridersclub.friend.enums.FriendRequestStatus;
import com.ridersclub.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendRequestRepository extends JpaRepository<FriendRequest, Long> {
    boolean existsBySenderAndReceiverAndStatus(User sender, User receiver, FriendRequestStatus status);

    boolean existsBySenderAndReceiver(User sender, User receiver);

    Optional<FriendRequest> findBySenderAndReceiver(User sender, User receiver);

    Optional<FriendRequest> findBySenderAndReceiverAndStatus(User sender, User receiver, FriendRequestStatus status);

    List<FriendRequest> findByReceiverAndStatus(User receiver, FriendRequestStatus status);

    List<FriendRequest> findBySenderAndStatus(User sender, FriendRequestStatus status);
}
