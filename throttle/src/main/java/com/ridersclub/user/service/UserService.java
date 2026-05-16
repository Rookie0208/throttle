package com.ridersclub.user.service;

import java.util.List;
import java.util.UUID;
import java.util.Comparator;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.extern.slf4j.Slf4j;

import com.ridersclub.bike.service.BikeRegistryService;
import com.ridersclub.common.enums.Gender;
import com.ridersclub.common.enums.Status;
import com.ridersclub.friend.repository.FriendshipRepository;
import com.ridersclub.user.dto.request.UpdateProfileRequest;
import com.ridersclub.user.dto.response.UserProfileResponse;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserRepository;

@Slf4j
@Service
@Transactional
public class UserService {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private com.ridersclub.user.repository.UserFollowRepository userFollowRepository;

    @Autowired
    private com.ridersclub.user.repository.UserBikeRepository userBikeRepository;

    @Autowired
    private com.ridersclub.user.repository.UserAchievementRepository userAchievementRepository;

    @Autowired
    private com.ridersclub.ride.repository.RideStatsRepository rideStatsRepository;

    @Autowired
    private com.ridersclub.ride.repository.RideParticipantRepository rideParticipantRepository;

    @Autowired
    private com.ridersclub.ride.repository.RideRepository rideRepository;

    @Autowired
    private com.ridersclub.ride.repository.ClubMemberRepository clubMemberRepository;

    @Autowired
    private FriendshipRepository friendshipRepository;

    @Autowired
    private BikeRegistryService bikeRegistryService;

    // --- helper methods used by other services ---
    @Transactional(readOnly = true)
    public java.util.Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    @Transactional(readOnly = true)
    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }

    @Transactional(readOnly = true)
    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    public User save(User user) {
        return userRepository.save(user);
    }

    @Transactional(readOnly = true)
    public User getUserByUuid(UUID uuid) {
        return userRepository.findByUuid(uuid.toString())
                .orElseThrow(() -> new com.ridersclub.common.exception.UserNotFoundException("User not found"));
    }

    private Gender getGenderFromPronoun(String pronoun) {
        if (pronoun == null) {
            return Gender.MALE;
        }
        switch (pronoun.toLowerCase()) {
            case "he/him":
            case "he_him":
                return Gender.MALE;
            case "she/her":
            case "she_her":
                return Gender.FEMALE;
            default:
                return Gender.MALE;
        }
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new com.ridersclub.common.exception.UserNotFoundException("User not found"));
        return new UserProfileResponse(user);
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfileByUUID(String uuidStr) {
        return getProfileByUUID(uuidStr, uuidStr);
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfileByUUID(String uuidStr, String viewerUuid) {
        User user = userRepository.findByUuid(uuidStr)
                .orElseThrow(() -> new com.ridersclub.common.exception.UserNotFoundException("User not found"));
        User viewer = viewerUuid == null || viewerUuid.isBlank()
                ? null
                : userRepository.findByUuid(viewerUuid).orElse(null);
        boolean isSelf = viewer != null && user.getUuid().equals(viewer.getUuid());
        boolean isFriend = viewer != null && !isSelf && friendshipRepository.existsByUserAndFriend(viewer, user);
        String visibilityMode = isSelf ? "self" : isFriend ? "friend" : "public";

        UserProfileResponse response = new UserProfileResponse(user);

        // Fetch bikes
        List<com.ridersclub.user.entity.UserBike> bikes = userBikeRepository.findByUserId(user.getId());
        response.setBikes(bikes.stream().map(bikeRegistryService::mapUserBike).toList());
        response.setBikeCount(bikes.size());

        // Fetch achievements
        List<com.ridersclub.user.entity.UserAchievement> achievements = userAchievementRepository
                .findByUserId(user.getId());
        response.setAchievements(achievements.stream().map(a -> new UserProfileResponse.UserAchievementDto(
                a.getTitle(), a.getDescription(), a.getIconName())).toList());
        response.setBadgeCount(achievements.size());

        // Fetch Ride Stats
        List<com.ridersclub.ride.entity.RideStats> stats = rideStatsRepository.findByUserId(user.getUuid());

        int totalRides = 0;
        double totalMiles = 0;
        double totalKm = 0;
        long totalDurationMin = 0;

        for (com.ridersclub.ride.entity.RideStats stat : stats) {
            totalRides++;
            totalKm += stat.getDistanceKm();
            double miles = stat.getDistanceKm() * 0.621371;
            totalMiles += miles;
            totalDurationMin += stat.getDurationMinutes();

            // For simplicity, treating all stats as "recent" or weekly in this MVP unless
            // we have a date on stats.
            // RideStats doesn't have a date, so we will just use a fraction or all of it.
            // For now, let's just add it all to weekly or mock weekly as the last 7 days of
            // rides if we fetch the actual ride dates.
        }

        response.setTotalRides(totalRides);
        response.setTotalMiles(Math.round(totalMiles * 10.0) / 10.0);
        response.setTotalKm(Math.round(totalKm * 10.0) / 10.0);
        response.setTotalDuration(totalDurationMin / 60);

        // Let's get actual rides for weekly stats & history
        List<com.ridersclub.ride.entity.RideParticipant> participants = rideParticipantRepository
                .findByUser_IdAndRsvpStatusNot(user.getId(), Status.EXITED);
        List<com.ridersclub.ride.entity.Ride> userRides = rideRepository.findAllById(
                participants.stream().map(p -> p.getRide().getId()).toList());
        java.time.LocalDateTime now = java.time.LocalDateTime.now();

        // Calculate weekly stats from actual rides in the last 7 days
        java.time.LocalDateTime oneWeekAgo = now.minusDays(7);
        List<com.ridersclub.ride.entity.Ride> weeklyRides = userRides.stream()
                .filter(r -> r.getEndTime() != null && r.getEndTime().isAfter(oneWeekAgo))
                .toList();

        int weeklyMilesSum = 0;
        for (com.ridersclub.ride.entity.Ride r : weeklyRides) {
            // Find stats for this ride
            var optStat = stats.stream().filter(s -> s.getRideId().equals(String.valueOf(r.getId()))).findFirst();
            if (optStat.isPresent()) {
                weeklyMilesSum += (int) (optStat.get().getDistanceKm() * 0.621371);
            }
        }
        response.setWeeklyMiles(weeklyMilesSum);
        // hardcode weekly averages for now if no data
        response.setWeeklyAvgMph(weeklyMilesSum > 0 ? 45.5 : 0.0);
        response.setWeeklyDuration(weeklyRides.size() * 2L);

        // Recent completed rides (last 3) pushed down to DB
        List<Long> joinedRideIds = participants.stream().map(p -> p.getRide().getId()).toList();
        List<com.ridersclub.ride.entity.Ride> recentRidesEntities = rideRepository
                .findTop3ByIdInAndStatusOrderByStartTimeDesc(joinedRideIds,
                        com.ridersclub.common.enums.Status.COMPLETED);

        List<UserProfileResponse.RideSummaryDto> recentRides = recentRidesEntities.stream()
                .map(r -> {
                    double miles = 0.0;
                    long duration = 0;
                    var optStat = stats.stream().filter(s -> s.getRideId().equals(String.valueOf(r.getId())))
                            .findFirst();
                    if (optStat.isPresent()) {
                        miles = optStat.get().getDistanceKm() * 0.621371;
                        duration = optStat.get().getDurationMinutes();
                    }
                    return new UserProfileResponse.RideSummaryDto(
                            r.getUuid(),
                            r.getTitle(),
                            r.getStartTime().getMonth().name().substring(0, 3) + " " + r.getStartTime().getDayOfMonth(),
                            r.getStartTime().toString(),
                            Math.round(miles * 10.0) / 10.0,
                            optStat.map(com.ridersclub.ride.entity.RideStats::getDistanceKm).orElse(0.0),
                            optStat.map(com.ridersclub.ride.entity.RideStats::getAvgSpeed).orElse(0.0),
                            duration,
                            (duration / 60) + "h " + (duration % 60) + "m");
                })
                .toList();
        response.setRecentRides(recentRides);

        response.setPublicGroups(
                clubMemberRepository.findByUser_Uuid(user.getUuid()).stream()
                        .map(com.ridersclub.ride.entity.ClubMember::getClub)
                        .distinct()
                        .map(club -> new UserProfileResponse.PublicGroupDto(
                                club.getUuid(),
                                club.getName(),
                                club.getTitle()))
                        .toList());

        userRides.stream()
                .filter(r -> r.getStatus() == com.ridersclub.common.enums.Status.ACTIVE
                        || r.getStatus() == com.ridersclub.common.enums.Status.PARTIAL_STARTED
                        || r.getStatus() == com.ridersclub.common.enums.Status.READY_TO_START
                        || r.getStatus() == com.ridersclub.common.enums.Status.IN_PROGRESS)
                .max(Comparator.comparing(com.ridersclub.ride.entity.Ride::getStartTime))
                .ifPresent(activeRide -> response.setTodayRide(new UserProfileResponse.UpcomingRideDto(
                        activeRide.getUuid(),
                        activeRide.getUuid(),
                        activeRide.getGroups().stream()
                                .filter(group -> group.getParentGroup() == null)
                                .findFirst()
                                .map(group -> group.getUuid())
                                .orElse(null),
                        activeRide.getTitle(),
                        activeRide.getDescription(),
                        activeRide.getRideType(),
                        activeRide.getMaxRiders(),
                        ((activeRide.getCreatedBy().getFirstName() != null ? activeRide.getCreatedBy().getFirstName() : "")
                                + " "
                                + (activeRide.getCreatedBy().getLastName() != null ? activeRide.getCreatedBy().getLastName() : "")).trim(),
                        activeRide.getVisibility().name(),
                        "IN PROGRESS • " + activeRide.getStartTime().getMonth().name().substring(0, 3) + " "
                                + activeRide.getStartTime().getDayOfMonth() + " • "
                                + activeRide.getStartTime().getHour() + ":"
                                + String.format("%02d", activeRide.getStartTime().getMinute()),
                        activeRide.getStartTime().getHour() + ":"
                                + String.format("%02d", activeRide.getStartTime().getMinute()),
                        (int) rideParticipantRepository.countByRide_Id(activeRide.getId()),
                        activeRide.getStartTime().toString(),
                        activeRide.getStatus().name())));

        userRides.stream()
                .filter(r -> r.getStartTime() != null && r.getStartTime().isAfter(now))
                .filter(r -> r.getStatus() != com.ridersclub.common.enums.Status.CANCELLED)
                .filter(r -> r.getStatus() != com.ridersclub.common.enums.Status.COMPLETED)
                .filter(r -> r.getStatus() != com.ridersclub.common.enums.Status.ARCHIVED)
                .min(Comparator.comparing(com.ridersclub.ride.entity.Ride::getStartTime))
                .ifPresent(ur -> {
                    response.setUpcomingRide(new UserProfileResponse.UpcomingRideDto(
                            ur.getUuid(),
                            ur.getUuid(),
                            ur.getGroups().stream()
                                    .filter(group -> group.getParentGroup() == null)
                                    .findFirst()
                                    .map(group -> group.getUuid())
                                    .orElse(null),
                            ur.getTitle(),
                            ur.getDescription(),
                            ur.getRideType(),
                            ur.getMaxRiders(),
                            ((ur.getCreatedBy().getFirstName() != null ? ur.getCreatedBy().getFirstName() : "")
                                    + " "
                                    + (ur.getCreatedBy().getLastName() != null ? ur.getCreatedBy().getLastName() : "")).trim(),
                            ur.getVisibility().name(),
                            ur.getMaxRiders() + " Riders • " + ur.getStartTime().getMonth().name().substring(0, 3) + " "
                                    + ur.getStartTime().getDayOfMonth() + " • " + ur.getStartTime().getHour() + ":"
                                    + String.format("%02d", ur.getStartTime().getMinute()),
                            ur.getStartTime().getHour() + ":"
                                    + String.format("%02d", ur.getStartTime().getMinute()),
                            (int) rideParticipantRepository.countByRide_Id(ur.getId()),
                            ur.getStartTime().toString(),
                            ur.getStatus().name()));
                });

        response.setVisibilityMode(visibilityMode);
        applyVisibility(response, visibilityMode);
        return response;
    }

    private void applyVisibility(UserProfileResponse response, String visibilityMode) {
        response.setPublicMessage(null);
        response.setEmergencyContacts(null);
        response.setBloodGroup(null);
        response.setAllergies(null);
        response.setCurrentMedication(null);
        response.setEmail(null);

        if ("self".equals(visibilityMode)) {
            return;
        }

        response.setTodayRide(null);
        response.setUpcomingRide(null);

        if ("friend".equals(visibilityMode)) {
            if (response.getRecentRides() != null) {
                response.setRecentRides(response.getRecentRides().stream()
                        .map(ride -> new UserProfileResponse.RideSummaryDto(
                                null,
                                ride.getTitle(),
                                ride.getDate(),
                                ride.getStartTime(),
                                ride.getMiles(),
                                ride.getDistanceKm(),
                                ride.getAvgSpeed(),
                                ride.getDurationMinutes(),
                                ride.getDuration()))
                        .toList());
            }
            return;
        }

        response.setPublicMessage("You are not a friend. Add friend to see their journey.");
        response.setWeeklyMiles(0);
        response.setWeeklyAvgMph(0);
        response.setWeeklyDuration(0);
        response.setBikes(null);
        response.setBikeCount(null);
        response.setAchievements(null);
        response.setRecentRides(null);
        response.setPublicGroups(null);
    }

    public UserProfileResponse updateProfile(
            String userId,
            UpdateProfileRequest request) {

        User user = userRepository.findByUuid(userId)
                .orElseThrow(() -> new com.ridersclub.common.exception.UserNotFoundException("User not found"));

        // Update only non-null fields
        if (request.getFirstName() != null)
            user.setFirstName(request.getFirstName());

        if (request.getLastName() != null)
            user.setLastName(request.getLastName());

        if (request.getBio() != null)
            user.setBio(request.getBio());

        if (request.getProfileImage() != null)
            user.setProfileImage(request.getProfileImage());

        if (request.getEmergencyContacts() != null)
            user.setEmergencyContacts(request.getEmergencyContacts());

        if (request.getBloodGroup() != null)
            user.setBloodGroup(request.getBloodGroup());

        if (request.getAllergies() != null)
            user.setAllergies(request.getAllergies());

        if (request.getCurrentMedication() != null)
            user.setCurrentMedication(request.getCurrentMedication());

        userRepository.save(user);

        return new UserProfileResponse(user);
    }

}
