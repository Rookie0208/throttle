package com.ridersclub.user.dto.response;

import java.util.List;

import com.ridersclub.user.entity.User;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Data
@NoArgsConstructor
@Getter
@Setter
public class UserProfileResponse {
    private String id;
    private String firstName;
    private String lastName;
    private String riderId;
    private String email;
    private String bio;
    private String profileImage;

    // Stats
    private int totalRides;
    private double totalMiles;
    private long totalDuration;
    private int weeklyMiles;
    private double weeklyAvgMph;
    private long weeklyDuration;

    // Lists
    private List<UserBikeDto> bikes;
    private List<UserAchievementDto> achievements;
    private List<RideSummaryDto> recentRides;
    private UpcomingRideDto todayRide;
    private UpcomingRideDto upcomingRide;
    private boolean subscriptionActive;
    private int bikeLimit;

    public UserProfileResponse(User user) {
        this.id = user.getUuid().toString();
        this.firstName = user.getFirstName();
        this.lastName = user.getLastName();
        this.riderId = user.getRiderId();
        this.email = user.getEmail();
        this.bio = user.getBio();
        this.profileImage = user.getProfileImage();
        this.subscriptionActive = user.isSubscriptionActive();
        this.bikeLimit = user.isSubscriptionActive() ? 999 : 3;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserBikeDto {
        private Long id;
        private Long bikeMasterId;
        private String make;
        private String brand;
        private String model;
        private String variant;
        private Integer year;
        private String type;
        private String category;
        private String bikeType;
        private Integer engineCc;
        private java.math.BigDecimal tankCapacity;
        private Integer range;
        private Integer comfortScore;
        private boolean primary;
        private boolean verified;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserAchievementDto {
        private String title;
        private String description;
        private String iconName;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RideSummaryDto {
        private String id;
        private String title;
        private String date; // formatted date short, e.g. "Feb 13"
        private double miles;
        private String duration; // formatted duration, e.g. "2h 15m"
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpcomingRideDto {
        private String uuid;
        private String id;
        private String groupUuid;
        private String title;
        private String description;
        private String createdByName;
        private String visibility;
        private String subtitle; // e.g. "8 Riders • Feb 15 • 7:30 AM"
        private String time;
        private Integer riders;
        private String startTime;
        private String status;
    }
}
