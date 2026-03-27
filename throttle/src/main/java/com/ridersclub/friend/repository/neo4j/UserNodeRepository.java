package com.ridersclub.friend.repository.neo4j;

import com.ridersclub.friend.entity.UserNode;
import org.springframework.data.neo4j.repository.Neo4jRepository;
import org.springframework.stereotype.Repository;

/**
 * Neo4j repository for UserNode graph entities.
 * All graph queries use Neo4jClient directly to avoid SDN scalar-mapping limitations.
 * This repository is retained for potential future use with entity-level operations.
 */
@Repository
public interface UserNodeRepository extends Neo4jRepository<UserNode, String> {
}
