package com.ridersclub.friend.entity;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.neo4j.core.schema.Id;
import org.springframework.data.neo4j.core.schema.Node;

/**
 * Represents a User node in the Neo4j graph.
 * All graph writes use Neo4jClient directly — this class exists for schema documentation
 * and potential future use with Spring Data Neo4j.
 */
@Node("User")
@Getter
@Setter
public class UserNode {

    @Id
    private String id; // maps to User.uuid

    private String firstName;
    private String lastName;
}
