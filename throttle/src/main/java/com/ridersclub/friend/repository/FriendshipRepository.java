package com.ridersclub.friend.repository;

import com.ridersclub.friend.entity.Friendship;
import com.ridersclub.friend.entity.FriendshipId;
import com.ridersclub.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FriendshipRepository extends JpaRepository<Friendship, FriendshipId> {
    List<Friendship> findByUser(User user);

    boolean existsByUserAndFriend(User user, User friend);

    void deleteByUserAndFriend(User user, User friend);
}
