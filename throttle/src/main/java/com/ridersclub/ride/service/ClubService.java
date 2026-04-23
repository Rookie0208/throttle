package com.ridersclub.ride.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ridersclub.common.Utils.UserUtility;
import com.ridersclub.common.enums.NotificationType;
import com.ridersclub.friend.entity.Friendship;
import com.ridersclub.friend.repository.FriendshipRepository;
import com.ridersclub.notification.service.NotificationService;
import com.ridersclub.ride.dto.request.AddClubMembersRequest;
import com.ridersclub.ride.dto.request.CreateClubRequest;
import com.ridersclub.ride.dto.request.CreateClubSubgroupRequest;
import com.ridersclub.ride.dto.response.ClubMemberResponse;
import com.ridersclub.ride.dto.response.ClubResponse;
import com.ridersclub.ride.dto.response.ClubSubgroupResponse;
import com.ridersclub.ride.entity.Club;
import com.ridersclub.ride.entity.ClubMember;
import com.ridersclub.ride.entity.ClubSubgroup;
import com.ridersclub.ride.entity.ClubSubgroupMember;
import com.ridersclub.ride.repository.ClubMemberRepository;
import com.ridersclub.ride.repository.ClubRepository;
import com.ridersclub.ride.repository.ClubSubgroupMemberRepository;
import com.ridersclub.ride.repository.ClubSubgroupRepository;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.entity.UserBike;
import com.ridersclub.user.repository.UserBikeRepository;
import com.ridersclub.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class ClubService {

    private final ClubRepository clubRepository;
    private final ClubMemberRepository clubMemberRepository;
    private final ClubSubgroupRepository clubSubgroupRepository;
    private final ClubSubgroupMemberRepository clubSubgroupMemberRepository;
    private final UserRepository userRepository;
    private final UserBikeRepository userBikeRepository;
    private final FriendshipRepository friendshipRepository;
    private final NotificationService notificationService;

    public ClubResponse createClub(CreateClubRequest request, String currentUserUuid) {
        final User creator = findUser(currentUserUuid);
        final String trimmedName = request.getName().trim();

        if (clubRepository.existsByNameIgnoreCase(trimmedName)) {
            throw new RuntimeException("A club with this name already exists");
        }

        final Club club = new Club();
        club.setUuid(UserUtility.generateUUID("CLUB"));
        club.setName(trimmedName);
        club.setTitle(trimToNull(request.getTitle()));
        club.setDescription(trimToNull(request.getDescription()));
        club.setCreatedBy(creator);

        final Club savedClub = clubRepository.save(club);

        final ClubMember member = new ClubMember();
        member.setClub(savedClub);
        member.setUser(creator);
        member.setRole("ADMIN");
        clubMemberRepository.save(member);

        return getClubDetails(savedClub.getUuid(), currentUserUuid);
    }

    @Transactional(readOnly = true)
    public List<ClubResponse> getMyClubs(String currentUserUuid) {
        return clubMemberRepository.findByUser_Uuid(currentUserUuid).stream()
                .map(ClubMember::getClub)
                .distinct()
                .map(club -> toClubResponse(club, currentUserUuid, false))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ClubResponse> discoverClubs(String currentUserUuid, String query) {
        final List<Club> clubs = (query == null || query.trim().isEmpty())
                ? clubRepository.findAll().stream()
                        .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()))
                        .limit(20)
                        .toList()
                : clubRepository.findTop20ByNameContainingIgnoreCaseOrTitleContainingIgnoreCaseOrderByCreatedAtDesc(
                        query.trim(),
                        query.trim());

        return clubs.stream()
                .map(club -> toClubResponse(club, currentUserUuid, false))
                .toList();
    }

    @Transactional(readOnly = true)
    public ClubResponse getClubDetails(String clubUuid, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        ensureMembership(club, currentUserUuid);
        return toClubResponse(club, currentUserUuid, true);
    }

    public void joinClub(String clubUuid, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        final User user = findUser(currentUserUuid);

        if (clubMemberRepository.existsByClub_IdAndUser_Id(club.getId(), user.getId())) {
            return;
        }

        final ClubMember member = new ClubMember();
        member.setClub(club);
        member.setUser(user);
        member.setRole("MEMBER");
        clubMemberRepository.save(member);

        notifyClubAdminsOfNewMember(club, user);
    }

    public void leaveClub(String clubUuid, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        final User user = findUser(currentUserUuid);
        final ClubMember membership = clubMemberRepository.findByClub_IdAndUser_Id(club.getId(), user.getId())
                .orElseThrow(() -> new RuntimeException("You are not a club member"));

        final long adminCount = clubMemberRepository.findByClub_Id(club.getId()).stream()
                .filter(member -> "ADMIN".equalsIgnoreCase(member.getRole()))
                .count();
        if ("ADMIN".equalsIgnoreCase(membership.getRole()) && adminCount <= 1) {
            throw new RuntimeException("Promote another admin before leaving this club");
        }

        clubSubgroupMemberRepository.findAll().stream()
                .filter(item -> item.getUser().getId().equals(user.getId())
                        && item.getSubgroup().getClub().getId().equals(club.getId()))
                .forEach(item -> clubSubgroupMemberRepository.deleteById(item.getId()));
        clubMemberRepository.deleteByClub_IdAndUser_Id(club.getId(), user.getId());
    }

    @Transactional(readOnly = true)
    public List<ClubMemberResponse> getClubMembers(String clubUuid, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        ensureMembership(club, currentUserUuid);

        return clubMemberRepository.findByClub_Id(club.getId()).stream()
                .map(this::toMemberResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ClubMemberResponse> searchMemberCandidates(String clubUuid, String currentUserUuid, String query) {
        final Club club = findClub(clubUuid);
        ensureAdmin(club, currentUserUuid);
        final User currentUser = findUser(currentUserUuid);

        final String safeQuery = query == null ? "" : query.trim();
        final Set<Long> existingIds = clubMemberRepository.findByClub_Id(club.getId()).stream()
                .map(member -> member.getUser().getId())
                .collect(Collectors.toSet());
        final LinkedHashSet<User> orderedCandidates = new LinkedHashSet<>();

        friendshipRepository.findByUser(currentUser).stream()
                .map(Friendship::getFriend)
                .filter(friend -> !existingIds.contains(friend.getId()))
                .filter(friend -> matchesProfileQuery(friend, safeQuery))
                .sorted(Comparator.comparing(friend -> displayName(friend).toLowerCase(Locale.ROOT)))
                .forEach(orderedCandidates::add);

        if (orderedCandidates.size() < 20) {
            final List<User> fallbackMatches = safeQuery.isEmpty()
                    ? userRepository.findAll().stream().limit(20).toList()
                    : userRepository.searchByProfileFields(safeQuery).stream().limit(20).toList();

            fallbackMatches.stream()
                    .filter(user -> !existingIds.contains(user.getId()))
                    .filter(user -> !user.getId().equals(currentUser.getId()))
                    .sorted(Comparator.comparing(user -> displayName(user).toLowerCase(Locale.ROOT)))
                    .forEach(orderedCandidates::add);
        }

        return orderedCandidates.stream()
                .limit(20)
                .map(this::toCandidateResponse)
                .toList();
    }

    public void addMembers(String clubUuid, AddClubMembersRequest request, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        ensureAdmin(club, currentUserUuid);

        final Set<String> userUuids = new LinkedHashSet<>(
                request.getUserUuids().stream()
                        .filter(item -> item != null && !item.trim().isEmpty())
                        .map(String::trim)
                        .toList());

        for (String userUuid : userUuids) {
            final User user = findUser(userUuid);
            if (clubMemberRepository.existsByClub_IdAndUser_Id(club.getId(), user.getId())) {
                continue;
            }
            final ClubMember member = new ClubMember();
            member.setClub(club);
            member.setUser(user);
            member.setRole("MEMBER");
            clubMemberRepository.save(member);
        }
    }

    public void updateMemberRole(String clubUuid, String targetUserUuid, String role, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        ensureAdmin(club, currentUserUuid);

        final User target = findUser(targetUserUuid);
        final ClubMember member = clubMemberRepository.findByClub_IdAndUser_Id(club.getId(), target.getId())
                .orElseThrow(() -> new RuntimeException("Member not found"));

        final String normalizedRole = normalizeRole(role);
        if (member.getUser().getUuid().equals(currentUserUuid) && "MEMBER".equals(normalizedRole)) {
            final long adminCount = clubMemberRepository.findByClub_Id(club.getId()).stream()
                    .filter(item -> "ADMIN".equalsIgnoreCase(item.getRole()))
                    .count();
            if (adminCount <= 1) {
                throw new RuntimeException("This club needs at least one admin");
            }
        }

        member.setRole(normalizedRole);
        clubMemberRepository.save(member);
    }

    public void removeMember(String clubUuid, String targetUserUuid, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        ensureAdmin(club, currentUserUuid);

        final User target = findUser(targetUserUuid);
        final ClubMember member = clubMemberRepository.findByClub_IdAndUser_Id(club.getId(), target.getId())
                .orElseThrow(() -> new RuntimeException("Member not found"));

        final long adminCount = clubMemberRepository.findByClub_Id(club.getId()).stream()
                .filter(item -> "ADMIN".equalsIgnoreCase(item.getRole()))
                .count();
        if ("ADMIN".equalsIgnoreCase(member.getRole()) && adminCount <= 1) {
            throw new RuntimeException("This club needs at least one admin");
        }

        clubSubgroupMemberRepository.findAll().stream()
                .filter(item -> item.getUser().getId().equals(target.getId())
                        && item.getSubgroup().getClub().getId().equals(club.getId()))
                .forEach(item -> clubSubgroupMemberRepository.deleteById(item.getId()));
        clubMemberRepository.deleteByClub_IdAndUser_Id(club.getId(), target.getId());
    }

    @Transactional(readOnly = true)
    public List<ClubSubgroupResponse> getSubgroups(String clubUuid, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        ensureMembership(club, currentUserUuid);

        return clubSubgroupRepository.findByClub_IdOrderByCreatedAtDesc(club.getId()).stream()
                .map(subgroup -> toSubgroupResponse(subgroup, currentUserUuid))
                .toList();
    }

    public ClubSubgroupResponse createSubgroup(String clubUuid, CreateClubSubgroupRequest request, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        ensureAdmin(club, currentUserUuid);

        final String subgroupName = request.getName().trim();
        if (clubSubgroupRepository.existsByClub_IdAndNameIgnoreCase(club.getId(), subgroupName)) {
            throw new RuntimeException("A subgroup with this name already exists");
        }

        final User actor = findUser(currentUserUuid);
        final ClubSubgroup subgroup = new ClubSubgroup();
        subgroup.setUuid(UserUtility.generateUUID("CSUB"));
        subgroup.setClub(club);
        subgroup.setName(subgroupName);
        subgroup.setCreatedBy(actor);
        final ClubSubgroup saved = clubSubgroupRepository.save(subgroup);

        final Set<String> memberUuids = new LinkedHashSet<>();
        memberUuids.add(currentUserUuid);
        if (request.getMemberUuids() != null) {
            memberUuids.addAll(request.getMemberUuids().stream()
                    .filter(item -> item != null && !item.trim().isEmpty())
                    .map(String::trim)
                    .toList());
        }

        for (String userUuid : memberUuids) {
            final User user = findUser(userUuid);
            if (!clubMemberRepository.existsByClub_IdAndUser_Id(club.getId(), user.getId())) {
                continue;
            }
            if (clubSubgroupMemberRepository.existsBySubgroup_IdAndUser_Id(saved.getId(), user.getId())) {
                continue;
            }
            final ClubSubgroupMember member = new ClubSubgroupMember();
            member.setSubgroup(saved);
            member.setUser(user);
            clubSubgroupMemberRepository.save(member);
        }

        return toSubgroupResponse(saved, currentUserUuid);
    }

    @Transactional(readOnly = true)
    public List<ClubMemberResponse> getSubgroupMembers(String subgroupUuid, String currentUserUuid) {
        final ClubSubgroup subgroup = findSubgroup(subgroupUuid);
        ensureMembership(subgroup.getClub(), currentUserUuid);

        return clubSubgroupMemberRepository.findBySubgroup_Id(subgroup.getId()).stream()
                .map(member -> ClubMemberResponse.builder()
                        .userUuid(member.getUser().getUuid())
                        .firstName(member.getUser().getFirstName())
                        .lastName(member.getUser().getLastName())
                        .riderId(member.getUser().getRiderId())
                        .profileImage(member.getUser().getProfileImage())
                        .bike(primaryBikeLabel(member.getUser()))
                        .role("MEMBER")
                        .joinedAt(member.getJoinedAt())
                        .build())
                .toList();
    }

    public Club findClub(String clubUuid) {
        return clubRepository.findByUuid(clubUuid)
                .orElseThrow(() -> new RuntimeException("Club not found"));
    }

    public ClubSubgroup findSubgroup(String subgroupUuid) {
        return clubSubgroupRepository.findByUuid(subgroupUuid)
                .orElseThrow(() -> new RuntimeException("Subgroup not found"));
    }

    public boolean isClubMember(String clubUuid, String currentUserUuid) {
        final Club club = findClub(clubUuid);
        final User user = findUser(currentUserUuid);
        return clubMemberRepository.existsByClub_IdAndUser_Id(club.getId(), user.getId());
    }

    public boolean isSubgroupMember(String subgroupUuid, String currentUserUuid) {
        final ClubSubgroup subgroup = findSubgroup(subgroupUuid);
        final User user = findUser(currentUserUuid);
        return clubSubgroupMemberRepository.existsBySubgroup_IdAndUser_Id(subgroup.getId(), user.getId())
                || isClubAdmin(subgroup.getClub(), currentUserUuid);
    }

    private ClubResponse toClubResponse(Club club, String currentUserUuid, boolean includeSubgroups) {
        final List<ClubMember> members = clubMemberRepository.findByClub_Id(club.getId());
        final ClubMember myMembership = members.stream()
                .filter(member -> member.getUser().getUuid().equals(currentUserUuid))
                .findFirst()
                .orElse(null);

        final List<ClubSubgroupResponse> subgroups = includeSubgroups
                ? clubSubgroupRepository.findByClub_IdOrderByCreatedAtDesc(club.getId()).stream()
                        .map(subgroup -> toSubgroupResponse(subgroup, currentUserUuid))
                        .toList()
                : List.of();

        return ClubResponse.builder()
                .uuid(club.getUuid())
                .name(club.getName())
                .title(club.getTitle())
                .description(club.getDescription())
                .bannerUrl(club.getBannerUrl())
                .memberCount(members.size())
                .subgroupCount((int) clubSubgroupRepository.findByClub_IdOrderByCreatedAtDesc(club.getId()).size())
                .myRole(myMembership == null ? null : myMembership.getRole())
                .member(myMembership != null)
                .createdByName(displayName(club.getCreatedBy()))
                .createdAt(club.getCreatedAt())
                .subgroups(subgroups)
                .build();
    }

    private ClubSubgroupResponse toSubgroupResponse(ClubSubgroup subgroup, String currentUserUuid) {
        final User currentUser = findUser(currentUserUuid);
        return ClubSubgroupResponse.builder()
                .uuid(subgroup.getUuid())
                .name(subgroup.getName())
                .memberCount((int) clubSubgroupMemberRepository.countBySubgroup_Id(subgroup.getId()))
                .member(clubSubgroupMemberRepository.existsBySubgroup_IdAndUser_Id(subgroup.getId(), currentUser.getId())
                        || isClubAdmin(subgroup.getClub(), currentUserUuid))
                .createdAt(subgroup.getCreatedAt())
                .build();
    }

    private ClubMemberResponse toMemberResponse(ClubMember member) {
        return ClubMemberResponse.builder()
                .userUuid(member.getUser().getUuid())
                .firstName(member.getUser().getFirstName())
                .lastName(member.getUser().getLastName())
                .riderId(member.getUser().getRiderId())
                .profileImage(member.getUser().getProfileImage())
                .bike(primaryBikeLabel(member.getUser()))
                .role(member.getRole())
                .joinedAt(member.getJoinedAt())
                .build();
    }

    private ClubMemberResponse toCandidateResponse(User user) {
        return ClubMemberResponse.builder()
                .userUuid(user.getUuid())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .riderId(user.getRiderId())
                .profileImage(user.getProfileImage())
                .bike(primaryBikeLabel(user))
                .role("MEMBER")
                .build();
    }

    private String primaryBikeLabel(User user) {
        final List<UserBike> bikes = userBikeRepository.findByUserId(user.getId());
        if (bikes.isEmpty()) {
            return null;
        }
        final UserBike bike = bikes.stream()
                .sorted((a, b) -> Boolean.compare(b.isPrimary(), a.isPrimary()))
                .findFirst()
                .orElse(bikes.get(0));

        final List<String> parts = new ArrayList<>();
        if (bike.getMake() != null && !bike.getMake().isBlank()) {
            parts.add(bike.getMake().trim());
        }
        if (bike.getModel() != null && !bike.getModel().isBlank()) {
            parts.add(bike.getModel().trim());
        }
        if (bike.getVariant() != null && !bike.getVariant().isBlank()) {
            parts.add(bike.getVariant().trim());
        }
        return parts.isEmpty() ? null : String.join(" ", parts);
    }

    private User findUser(String userUuid) {
        return userRepository.findByUuid(userUuid)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private void ensureMembership(Club club, String currentUserUuid) {
        final User user = findUser(currentUserUuid);
        if (!clubMemberRepository.existsByClub_IdAndUser_Id(club.getId(), user.getId())) {
            throw new RuntimeException("Join this club to continue");
        }
    }

    private void ensureAdmin(Club club, String currentUserUuid) {
        if (!isClubAdmin(club, currentUserUuid)) {
            throw new RuntimeException("Only club admins can do that");
        }
    }

    private void notifyClubAdminsOfNewMember(Club club, User joinedUser) {
        final String joinedUserName = displayName(joinedUser);
        clubMemberRepository.findByClub_Id(club.getId()).stream()
                .filter(member -> "ADMIN".equalsIgnoreCase(member.getRole()))
                .map(ClubMember::getUser)
                .filter(admin -> !admin.getId().equals(joinedUser.getId()))
                .forEach(admin -> notificationService.createAndSend(
                        admin.getId(),
                        NotificationType.CLUB_MEMBER_JOINED,
                        "New club member",
                        joinedUserName + " joined " + club.getName() + ".",
                        club.getId(),
                        "CLUB"));
    }

    private boolean matchesProfileQuery(User user, String query) {
        if (query == null || query.isBlank()) {
            return true;
        }

        final String normalizedQuery = query.trim().toLowerCase(Locale.ROOT);
        return displayName(user).toLowerCase(Locale.ROOT).contains(normalizedQuery)
                || safeValue(user.getRiderId()).contains(normalizedQuery)
                || safeValue(user.getEmail()).contains(normalizedQuery);
    }

    private boolean isClubAdmin(Club club, String currentUserUuid) {
        final User user = findUser(currentUserUuid);
        return clubMemberRepository.findByClub_IdAndUser_Id(club.getId(), user.getId())
                .map(member -> "ADMIN".equalsIgnoreCase(member.getRole()))
                .orElse(false);
    }

    private String normalizeRole(String role) {
        final String normalized = role == null ? "" : role.trim().toUpperCase(Locale.ROOT);
        if (!"ADMIN".equals(normalized) && !"MEMBER".equals(normalized)) {
            throw new RuntimeException("Only ADMIN or MEMBER roles are supported");
        }
        return normalized;
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        final String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String displayName(User user) {
        final String first = user.getFirstName() == null ? "" : user.getFirstName().trim();
        final String last = user.getLastName() == null ? "" : user.getLastName().trim();
        final String fullName = (first + " " + last).trim();
        if (!fullName.isEmpty()) {
            return fullName;
        }
        final String riderId = user.getRiderId() == null ? "" : user.getRiderId().trim();
        return riderId.isEmpty() ? "Rider" : riderId;
    }

    private String safeValue(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }
}
