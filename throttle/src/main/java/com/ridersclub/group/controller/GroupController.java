package com.ridersclub.group.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.group.service.GroupService;
import com.ridersclub.user.entity.User;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/groups")
@RequiredArgsConstructor
public class GroupController {

    private final GroupService groupService;

    // Get my groups
    @GetMapping("/my")
    public ResponseEntity<?> getMyGroups(
            @AuthenticationPrincipal User currentUser) {

        return ResponseEntity.ok(
                groupService.getUserGroups(currentUser)
        );
    }

    // Get group details
    @GetMapping("/{id}")
    public ResponseEntity<?> getGroup(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                groupService.getGroupById(id)
        );
    }

    // Join group
    @PostMapping("/{id}/join")
    public ResponseEntity<?> joinGroup(
            @PathVariable Long id,
            @AuthenticationPrincipal User currentUser) {

        groupService.joinGroup(id, currentUser);
        return ResponseEntity.ok("Joined successfully");
    }
}