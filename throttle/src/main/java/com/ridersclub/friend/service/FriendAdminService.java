package com.ridersclub.friend.service;

import com.ridersclub.friend.entity.Friendship;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;
import com.ridersclub.friend.repository.FriendshipRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.neo4j.core.Neo4jClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Handles admin/operational operations: graph sync and debug introspection.
 * Deliberately separated from the business-facing FriendService.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FriendAdminService {

    private final UserRepository userRepository;
    private final FriendshipRepository friendshipRepository;
    private final Neo4jClient neo4jClient;

    @Transactional
    public void syncGraphData() {
        log.info("Starting complete graph data synchronization...");
        try {
            List<User> users = userRepository.findAll();
            log.info("Syncing {} users to Neo4j", users.size());
            for (User u : users) {
                if (u.getUuid() == null || u.getUuid().isBlank()) continue;
                try {
                    neo4jClient.query(
                            "MERGE (u:User {id: $id}) SET u.firstName = $firstName, u.lastName = $lastName")
                            .bind(u.getUuid()).to("id")
                            .bind(u.getFirstName() != null ? u.getFirstName() : "").to("firstName")
                            .bind(u.getLastName() != null ? u.getLastName() : "").to("lastName")
                            .run();
                } catch (Exception e) {
                    log.error("Failed to merge user node for {}: {}", u.getUuid(), e.getMessage());
                }
            }

            List<Friendship> friendships = friendshipRepository.findAll();
            log.info("Syncing {} friendship edges to Neo4j", friendships.size());
            for (Friendship f : friendships) {
                if (f.getUser() == null || f.getFriend() == null
                        || f.getUser().getUuid() == null || f.getFriend().getUuid() == null) continue;
                try {
                    neo4jClient.query(
                            "MATCH (u1:User {id: $id1}), (u2:User {id: $id2}) MERGE (u1)-[:FRIENDS_WITH]-(u2)")
                            .bind(f.getUser().getUuid()).to("id1")
                            .bind(f.getFriend().getUuid()).to("id2")
                            .run();
                } catch (Exception e) {
                    log.error("Failed to merge edge for {} and {}: {}",
                            f.getUser().getUuid(), f.getFriend().getUuid(), e.getMessage());
                }
            }
            log.info("Graph synchronization complete.");
        } catch (Exception e) {
            log.error("Critical error during graph sync", e);
            throw new RuntimeException("Graph sync failed: " + e.getMessage(), e);
        }
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getGraphDebugInfo(String userUuid) {
        Map<String, Object> debug = new HashMap<>();
        debug.put("userUuid", userUuid);
        try {
            Long nodeCount = neo4jClient.query("MATCH (n:User {id: $id}) RETURN count(n)")
                    .bind(userUuid).to("id").fetchAs(Long.class).one().orElse(0L);
            debug.put("userNodeExists", nodeCount > 0);

            Long friendCount = neo4jClient.query("MATCH (u:User {id: $id})-[:FRIENDS_WITH]-(f) RETURN count(f)")
                    .bind(userUuid).to("id").fetchAs(Long.class).one().orElse(0L);
            debug.put("neo4jFriendCount", friendCount);

            Long totalNodes = neo4jClient.query("MATCH (n:User) RETURN count(n)")
                    .fetchAs(Long.class).one().orElse(0L);
            debug.put("totalGraphNodes", totalNodes);

            Long totalEdges = neo4jClient.query("MATCH ()-[:FRIENDS_WITH]-() RETURN count(*) / 2")
                    .fetchAs(Long.class).one().orElse(0L);
            debug.put("totalGraphEdges", totalEdges);

            List<String> friendIds = neo4jClient
                    .query("MATCH (u:User {id: $id})-[:FRIENDS_WITH]-(f) RETURN f.id")
                    .bind(userUuid).to("id").fetchAs(String.class).all().stream().toList();
            debug.put("friendIds", friendIds);
        } catch (Exception e) {
            log.error("Error fetching graph debug info for {}: {}", userUuid, e.getMessage());
            debug.put("error", e.getMessage());
        }
        return debug;
    }
}
