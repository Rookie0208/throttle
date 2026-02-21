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

import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.InMemoryUserRepo;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.io.IOException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {
    private JwtService jwtService;

    public JwtAuthFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    public void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");
        String bearerToken = (authHeader != null && authHeader.startsWith("Bearer ")) ? authHeader.substring(7) : null;
        try {
            if (bearerToken != null) {
                Claims claims = jwtService.parse(bearerToken).getBody();
                String userId = claims.getSubject();
               
                String rolesStr = (String) claims.get("roles");
                List<String> roles = Arrays.asList(rolesStr.split(","));
                Collection<SimpleGrantedAuthority> authorities = roles.stream()
                        .map(role -> new SimpleGrantedAuthority("ROLE_" + role)).collect(Collectors.toList());

                UsernamePasswordAuthenticationToken authentication =
            new UsernamePasswordAuthenticationToken(
                    userId,   // principal
                    null,     // credentials
                    authorities
            );

    authentication.setDetails(
            new WebAuthenticationDetailsSource().buildDetails(request)
    );

    SecurityContextHolder.getContext().setAuthentication(authentication);
            }
            filterChain.doFilter(request, response);
        } catch (Exception e) {
            throw new ServletException("Invalid or expired JWT token", e);
        } 
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest req) {
        String s = req.getRequestURI();
        if("OPTIONS".equalsIgnoreCase(req.getMethod())) return true;
        // ignore these urls
        return s.startsWith("/auth") || s.startsWith("/swagger-ui") || s.startsWith("/v3/api-docs") || s.equals("/") || s.startsWith("/api/health");
    }
}
