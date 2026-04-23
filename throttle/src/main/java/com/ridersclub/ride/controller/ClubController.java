package com.ridersclub.ride.controller;

import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ridersclub.common.dto.ApiResponse;
import com.ridersclub.ride.dto.request.AddClubMembersRequest;
import com.ridersclub.ride.dto.request.CreateClubRequest;
import com.ridersclub.ride.dto.request.CreateClubSubgroupRequest;
import com.ridersclub.ride.dto.response.ClubMemberResponse;
import com.ridersclub.ride.dto.response.ClubResponse;
import com.ridersclub.ride.dto.response.ClubSubgroupResponse;
import com.ridersclub.ride.service.ClubService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/clubs")
@RequiredArgsConstructor
public class ClubController {

    private final ClubService clubService;

    @PostMapping
    public ApiResponse<ClubResponse> createClub(
            @Valid @RequestBody CreateClubRequest request,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                clubService.createClub(request, currentUserUuid),
                "Club created successfully");
    }

    @GetMapping("/my")
    public ApiResponse<List<ClubResponse>> getMyClubs(Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(clubService.getMyClubs(currentUserUuid), "Clubs fetched");
    }

    @GetMapping("/discover")
    public ApiResponse<List<ClubResponse>> discoverClubs(
            @RequestParam(required = false) String query,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(clubService.discoverClubs(currentUserUuid, query), "Discover clubs fetched");
    }

    @GetMapping("/{clubUuid}")
    public ApiResponse<ClubResponse> getClubDetails(
            @PathVariable String clubUuid,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                clubService.getClubDetails(clubUuid, currentUserUuid),
                "Club details fetched");
    }

    @PostMapping("/{clubUuid}/join")
    public ApiResponse<Void> joinClub(
            @PathVariable String clubUuid,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        clubService.joinClub(clubUuid, currentUserUuid);
        return ApiResponse.success(null, "Joined club");
    }

    @PostMapping("/{clubUuid}/leave")
    public ApiResponse<Void> leaveClub(
            @PathVariable String clubUuid,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        clubService.leaveClub(clubUuid, currentUserUuid);
        return ApiResponse.success(null, "Left club");
    }

    @GetMapping("/{clubUuid}/members")
    public ApiResponse<List<ClubMemberResponse>> getClubMembers(
            @PathVariable String clubUuid,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                clubService.getClubMembers(clubUuid, currentUserUuid),
                "Club members fetched");
    }

    @GetMapping("/{clubUuid}/member-candidates")
    public ApiResponse<List<ClubMemberResponse>> searchMemberCandidates(
            @PathVariable String clubUuid,
            @RequestParam(required = false) String query,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                clubService.searchMemberCandidates(clubUuid, currentUserUuid, query),
                "Club member candidates fetched");
    }

    @PostMapping("/{clubUuid}/members")
    public ApiResponse<Void> addMembers(
            @PathVariable String clubUuid,
            @Valid @RequestBody AddClubMembersRequest request,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        clubService.addMembers(clubUuid, request, currentUserUuid);
        return ApiResponse.success(null, "Members added successfully");
    }

    @PutMapping("/{clubUuid}/members/{userUuid}/role")
    public ApiResponse<Void> updateRole(
            @PathVariable String clubUuid,
            @PathVariable String userUuid,
            @RequestBody java.util.Map<String, String> request,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        clubService.updateMemberRole(clubUuid, userUuid, request.get("role"), currentUserUuid);
        return ApiResponse.success(null, "Club member role updated");
    }

    @DeleteMapping("/{clubUuid}/members/{userUuid}")
    public ApiResponse<Void> removeMember(
            @PathVariable String clubUuid,
            @PathVariable String userUuid,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        clubService.removeMember(clubUuid, userUuid, currentUserUuid);
        return ApiResponse.success(null, "Club member removed");
    }

    @GetMapping("/{clubUuid}/subgroups")
    public ApiResponse<List<ClubSubgroupResponse>> getSubgroups(
            @PathVariable String clubUuid,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                clubService.getSubgroups(clubUuid, currentUserUuid),
                "Club subgroups fetched");
    }

    @PostMapping("/{clubUuid}/subgroups")
    public ApiResponse<ClubSubgroupResponse> createSubgroup(
            @PathVariable String clubUuid,
            @Valid @RequestBody CreateClubSubgroupRequest request,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                clubService.createSubgroup(clubUuid, request, currentUserUuid),
                "Club subgroup created successfully");
    }

    @GetMapping("/subgroups/{subgroupUuid}/members")
    public ApiResponse<List<ClubMemberResponse>> getSubgroupMembers(
            @PathVariable String subgroupUuid,
            Authentication authentication) {
        final String currentUserUuid = authentication.getPrincipal().toString();
        return ApiResponse.success(
                clubService.getSubgroupMembers(subgroupUuid, currentUserUuid),
                "Club subgroup members fetched");
    }
}
