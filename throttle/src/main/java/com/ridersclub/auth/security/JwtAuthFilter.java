package com.ridersclub.auth.security;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import lombok.extern.slf4j.Slf4j;

import com.ridersclub.user.entity.User;
import com.ridersclub.auth.service.TokenBlacklistService;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.io.IOException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
@Slf4j
public class JwtAuthFilter extends OncePerRequestFilter {
    private JwtService jwtService;
    private TokenBlacklistService tokenBlacklistService;

    public JwtAuthFilter(JwtService jwtService, TokenBlacklistService tokenBlacklistService) {
        this.jwtService = jwtService;
        this.tokenBlacklistService = tokenBlacklistService;
    }

    @Override
    public void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException, java.io.IOException {

        String authHeader = request.getHeader("Authorization");
        String bearerToken = (authHeader != null && authHeader.startsWith("Bearer ")) ? authHeader.substring(7) : null;
        try {
            if (bearerToken != null) {
                log.debug("Found Bearer token in request, validating...");
                if (tokenBlacklistService.isTokenBlacklisted(bearerToken)) {
                    log.warn("Attempt to use blacklisted token!");
                    throw new ServletException("Token has been blacklisted");
                }

                Claims claims = jwtService.parse(bearerToken).getBody();
                String userId = claims.getSubject();
                log.debug("Token parsed successfully. User ID: {}", userId);

                String rolesStr = (String) claims.get("roles");
                List<String> roles = Arrays.asList(rolesStr.split(","));
                Collection<SimpleGrantedAuthority> authorities = roles.stream()
                        .map(role -> new SimpleGrantedAuthority("ROLE_" + role)).collect(Collectors.toList());

                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        userId, // principal
                        null, // credentials
                        authorities);

                authentication.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request));

                SecurityContextHolder.getContext().setAuthentication(authentication);
            } else {
                log.debug("No Bearer token found in request headers");
            }
            filterChain.doFilter(request, response);
        } catch (Exception e) {
            log.error("Authentication failed: {}", e.getMessage());
            throw new ServletException("Invalid or expired JWT token", e);
        }
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        String s = req.getRequestURI();
        if ("OPTIONS".equalsIgnoreCase(req.getMethod()))
            return true;
        // ignore these urls
        return s.startsWith("/auth") || s.startsWith("/swagger-ui") || s.startsWith("/v3/api-docs") || s.equals("/")
                || s.startsWith("/api/health");
    }
}
