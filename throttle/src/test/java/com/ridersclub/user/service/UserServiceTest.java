package com.ridersclub.user.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import com.ridersclub.common.exception.UserNotFoundException;
import com.ridersclub.bike.service.BikeRegistryService;
import com.ridersclub.friend.repository.FriendshipRepository;
import com.ridersclub.ride.entity.RideStats;
import com.ridersclub.ride.repository.ClubMemberRepository;
import com.ridersclub.ride.repository.RideParticipantRepository;
import com.ridersclub.ride.repository.RideRepository;
import com.ridersclub.ride.repository.RideStatsRepository;
import com.ridersclub.user.dto.common.EmergencyContactPayload;
import com.ridersclub.user.dto.response.UserProfileResponse;
import com.ridersclub.user.entity.User;
import com.ridersclub.user.repository.UserAchievementRepository;
import com.ridersclub.user.repository.UserBikeRepository;
import com.ridersclub.user.repository.UserRepository;

class UserServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private FriendshipRepository friendshipRepository;
    @Mock
    private UserBikeRepository userBikeRepository;
    @Mock
    private UserAchievementRepository userAchievementRepository;
    @Mock
    private RideStatsRepository rideStatsRepository;
    @Mock
    private RideParticipantRepository rideParticipantRepository;
    @Mock
    private RideRepository rideRepository;
    @Mock
    private ClubMemberRepository clubMemberRepository;
    @Mock
    private BikeRegistryService bikeRegistryService;

    private UserService userService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
        userService = new UserService();
        inject("userRepository", userRepository);
        inject("friendshipRepository", friendshipRepository);
        inject("userBikeRepository", userBikeRepository);
        inject("userAchievementRepository", userAchievementRepository);
        inject("rideStatsRepository", rideStatsRepository);
        inject("rideParticipantRepository", rideParticipantRepository);
        inject("rideRepository", rideRepository);
        inject("clubMemberRepository", clubMemberRepository);
        inject("bikeRegistryService", bikeRegistryService);

        when(userBikeRepository.findByUserId(anyLong())).thenReturn(Collections.emptyList());
        when(userAchievementRepository.findByUserId(anyLong())).thenReturn(Collections.emptyList());
        when(rideParticipantRepository.findByUser_IdAndRsvpStatusNot(anyLong(), any())).thenReturn(Collections.emptyList());
        when(rideRepository.findAllById(any())).thenReturn(Collections.emptyList());
        when(rideRepository.findTop3ByIdInAndStatusOrderByStartTimeDesc(any(), any())).thenReturn(Collections.emptyList());
        when(clubMemberRepository.findByUser_Uuid(anyString())).thenReturn(Collections.emptyList());
    }

    private void inject(String fieldName, Object value) {
        try {
            var field = UserService.class.getDeclaredField(fieldName);
            field.setAccessible(true);
            field.set(userService, value);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private User buildUser(String uuid) {
        User user = new User();
        user.setId(7L);
        user.setUuid(uuid);
        user.setUsername("roadwolf");
        user.setRiderId("RID-7");
        user.setFirstName("Road");
        user.setLastName("Wolf");
        user.setEmail("roadwolf@example.com");
        user.setBio("Weekend rider");
        user.setBloodGroup("O+");
        user.setAllergies("Dust");
        user.setCurrentMedication("None");
        EmergencyContactPayload contact = new EmergencyContactPayload();
        contact.setName("Alex");
        contact.setRelation("Brother");
        contact.setPhoneNumber("+911234567890");
        user.setEmergencyContacts(List.of(contact));
        return user;
    }

    @Test
    void findByEmail_returnsOptional() {
        User user = new User();
        when(userRepository.findByEmail("a@b.com")).thenReturn(Optional.of(user));
        Optional<User> out = userService.findByEmail("a@b.com");
        assertTrue(out.isPresent());
    }

    @Test
    void existsByEmail_delegate() {
        when(userRepository.existsByEmail("x")).thenReturn(true);
        assertTrue(userService.existsByEmail("x"));
    }

    @Test
    void getProfileByUUID_missing() {
        when(userRepository.findByUuid(any())).thenReturn(Optional.empty());
        assertThrows(UserNotFoundException.class, () -> userService.getProfileByUUID(UUID.randomUUID().toString()));
    }

    @Test
    void getProfileByUUID_publicView_filtersPrivatePayload() {
        User target = buildUser("target-uuid");
        User viewer = buildUser("viewer-uuid");
        RideStats stat = new RideStats(1L, "ride-1", "target-uuid", 120.5, 180, 68.0);

        when(userRepository.findByUuid("target-uuid")).thenReturn(Optional.of(target));
        when(userRepository.findByUuid("viewer-uuid")).thenReturn(Optional.of(viewer));
        when(friendshipRepository.existsByUserAndFriend(viewer, target)).thenReturn(false);
        when(rideStatsRepository.findByUserId("target-uuid")).thenReturn(List.of(stat));

        UserProfileResponse response = userService.getProfileByUUID("target-uuid", "viewer-uuid");

        assertEquals("public", response.getVisibilityMode());
        assertEquals(120.5, response.getTotalKm());
        assertEquals(1, response.getTotalRides());
        assertEquals("You are not a friend. Add friend to see their journey.", response.getPublicMessage());
        assertNull(response.getEmail());
        assertNull(response.getEmergencyContacts());
        assertNull(response.getBloodGroup());
        assertNull(response.getAllergies());
        assertNull(response.getCurrentMedication());
        assertNull(response.getBikes());
        assertNull(response.getAchievements());
        assertNull(response.getRecentRides());
        assertNull(response.getPublicGroups());
        assertNull(response.getTodayRide());
        assertNull(response.getUpcomingRide());
        assertEquals(0, response.getWeeklyMiles());
        assertEquals(0.0, response.getWeeklyAvgMph());
        assertEquals(0, response.getWeeklyDuration());
    }

    @Test
    void getProfileByUUID_friendView_keepsLightweightJourneyData() {
        User target = buildUser("target-uuid");
        User viewer = buildUser("viewer-uuid");
        RideStats stat = new RideStats(1L, "ride-1", "target-uuid", 42.0, 90, 55.0);

        when(userRepository.findByUuid("target-uuid")).thenReturn(Optional.of(target));
        when(userRepository.findByUuid("viewer-uuid")).thenReturn(Optional.of(viewer));
        when(friendshipRepository.existsByUserAndFriend(viewer, target)).thenReturn(true);
        when(rideStatsRepository.findByUserId("target-uuid")).thenReturn(List.of(stat));

        UserProfileResponse response = userService.getProfileByUUID("target-uuid", "viewer-uuid");

        assertEquals("friend", response.getVisibilityMode());
        assertEquals(42.0, response.getTotalKm());
        assertNull(response.getPublicMessage());
        assertNull(response.getEmail());
        assertNull(response.getEmergencyContacts());
        assertNull(response.getBloodGroup());
        assertNull(response.getAllergies());
        assertNull(response.getCurrentMedication());
        assertNotNull(response.getRecentRides());
        assertNotNull(response.getPublicGroups());
        assertNotNull(response.getBikeCount());
        assertEquals(0, response.getBikeCount());
        assertNull(response.getTodayRide());
        assertNull(response.getUpcomingRide());
    }
}
