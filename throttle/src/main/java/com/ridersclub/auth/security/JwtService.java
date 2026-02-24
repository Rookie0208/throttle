package com.ridersclub.auth.security;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.time.Instant;
import java.util.Date;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Component;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

@Component
public class JwtService {
private static final String SECRET_KEY = "RidersAppSuperSecretKeyRidersAppSuperSecretKey";

public String generate(String subject, Map<String, Object> claims, long ttlSeconds) {
        Instant now = Instant.now();
    return Jwts.builder().setSubject(subject)       // userId
        .addClaims(claims)                              // contains metadata like roles, etc.
        .setIssuedAt(Date.from(now))
        .setExpiration(Date.from(now.plusSeconds(ttlSeconds)))
        .signWith(getSigningKey(), SignatureAlgorithm.HS256)
        .compact();
    }

    /**
     * @param take token
     * @return parsed JWT claims(meta data)
     */
    public Jws<Claims> parse(String token) {
        return Jwts.parserBuilder()
        .setSigningKey(getSigningKey())
        .build()
        .parseClaimsJws(token);
    }

private Key getSigningKey() {
    return Keys.hmacShaKeyFor(SECRET_KEY.getBytes(StandardCharsets.UTF_8));
}
}
