package com.ridersclub.common.Utils;

public class ApiConstants {
    public static final String API_VERSION = "/api/v1";

    // ================= AUTH MODULE =================
    public static final class Auth {

        public static final String BASE = API_VERSION + "/auth";

        public static final String REGISTER = "/register";
        public static final String LOGIN = "/login";

        // Google Auth
        public static final String GOOGLE_INITIATE = "/google/initiate";
        public static final String GOOGLE_VERIFY_OTP = "/google/verify-otp";
        public static final String GOOGLE_COMPLETE_REGISTRATION = "/google/complete-registration";

        // Test / health check
        public static final String TEST = "/test";
    }

    public static final class Rides {

        public static final String BASE = API_VERSION + "/rides";

        public static final String CREATE = "/create";
        public static final String MY_RIDES = "/my";
        public static final String DETAILS = "/{id}";
        public static final String START = "/{id}/start";
        public static final String COMPLETE = "/{id}/complete";
        public static final String CANCEL = "/{id}/cancel";
        public static final String JOIN = "/{id}/join";
        public static final String LIST = "/{id}/participants";
        public static final String STATS = "/{id}/stats";
    }

    public static final class RideCaptain {

        public static final String ASSIGN_ROLE = "/{rideId}/assign-role";
        public static final String REMOVE_RIDER = "/{rideId}/remove-rider";
    }

    public static final class RideParticipant {
        public static final String BASE = API_VERSION + "/participants";
        public static final String JOIN = "/{rideId}/join";
        public static final String LEAVE = "/{rideId}/leave";
        public static final String LIST = "/{rideId}";
    }

    public static final class Participants {

        public static final String JOIN = "/{id}/join";
        public static final String LEAVE = "/{id}/leave";
        public static final String LIST = "/{id}/participants";
        public static final String REMOVE = "/{id}/participants/{userId}";
        public static final String ROLE = "/{id}/participants/{userId}/role";
    }

    public static final class Checkpoints {

        public static final String BASE = "/{id}/checkpoints";
        public static final String UPDATE = "/{id}/checkpoints/{checkpointId}";
    }

    public static final class Stats {

        public static final String ADD = "/{id}/stats";
        public static final String GET = "/{id}/stats";
    }

    public static final class Notifications {

        public static final String BASE = API_VERSION + "/notifications";
        public static final String MY = "/my";
        public static final String MARK_AS_READ = "/{id}/read";
    }

    public static final class Message {

        public static final String BASE = API_VERSION + "/messages";
        public static final String SEND = "/send";
        public static final String GET_GROUP_MESSAGES = "/{groupUuid}";
        public static final String MARK_AS_READ = "/read";
    }
}
