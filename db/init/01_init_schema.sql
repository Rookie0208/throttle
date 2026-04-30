CREATE EXTENSION IF NOT EXISTS "pgcrypto";

--------------------------------------------------
-- USERS
--------------------------------------------------

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    uuid VARCHAR(100) UNIQUE NOT NULL,
    rider_id VARCHAR(30) UNIQUE NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    pronoun VARCHAR(20),
    gender VARCHAR(20),
    city VARCHAR(100),
    bio TEXT,
    profile_image VARCHAR(255),
    bike_type VARCHAR(100),
    role VARCHAR(20) DEFAULT 'RIDER',
    active BOOLEAN DEFAULT TRUE,
    subscription_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT now(),
    experience_years INT DEFAULT 0,
    emergency_contacts JSONB NOT NULL DEFAULT '[]'::jsonb,
    blood_group VARCHAR(10),
    allergies VARCHAR(1000),
    current_medication VARCHAR(1000)
);

CREATE INDEX idx_users_uuid ON users(uuid);
CREATE INDEX idx_users_rider_id ON users(rider_id);

--------------------------------------------------
-- CLUBS (COMMUNITIES)
--------------------------------------------------

CREATE TABLE clubs (
    id BIGSERIAL PRIMARY KEY,

    uuid VARCHAR(100) UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    name VARCHAR(150) NOT NULL,
    description TEXT,

    city VARCHAR(100),

    created_by BIGINT NOT NULL,

    visibility VARCHAR(20) DEFAULT 'PUBLIC'
        CHECK (visibility IN ('PUBLIC','PRIVATE')),

    created_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE CASCADE
);

--------------------------------------------------
-- CLUB MEMBERS
--------------------------------------------------

CREATE TABLE club_members (
    id BIGSERIAL PRIMARY KEY,

    club_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    role VARCHAR(20) DEFAULT 'MEMBER'
        CHECK (role IN ('ADMIN','MODERATOR','MEMBER')),

    joined_at TIMESTAMP DEFAULT now(),

    UNIQUE (club_id, user_id),

    FOREIGN KEY (club_id)
        REFERENCES clubs(id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_club_members_club ON club_members(club_id);

--------------------------------------------------
-- CLUB SUBGROUPS
--------------------------------------------------

CREATE TABLE club_subgroups (
    id BIGSERIAL PRIMARY KEY,

    uuid VARCHAR(100) UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    club_id BIGINT NOT NULL,
    created_by BIGINT NOT NULL,

    name VARCHAR(120) NOT NULL,

    created_at TIMESTAMP DEFAULT now(),

    UNIQUE (club_id, name),

    FOREIGN KEY (club_id)
        REFERENCES clubs(id)
        ON DELETE CASCADE,

    FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_club_subgroups_club ON club_subgroups(club_id);

--------------------------------------------------
-- CLUB SUBGROUP MEMBERS
--------------------------------------------------

CREATE TABLE club_subgroup_members (
    id BIGSERIAL PRIMARY KEY,

    subgroup_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    joined_at TIMESTAMP DEFAULT now(),

    UNIQUE (subgroup_id, user_id),

    FOREIGN KEY (subgroup_id)
        REFERENCES club_subgroups(id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_club_subgroup_members_subgroup ON club_subgroup_members(subgroup_id);
CREATE INDEX idx_club_subgroup_members_user ON club_subgroup_members(user_id);

--------------------------------------------------
-- CLUB MESSAGES
--------------------------------------------------

CREATE TABLE club_messages (
    id BIGSERIAL PRIMARY KEY,

    uuid VARCHAR(100) UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    sender_id BIGINT NOT NULL,
    club_id BIGINT NOT NULL,
    subgroup_id BIGINT,

    message TEXT,
    message_type VARCHAR(40) NOT NULL,

    created_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (sender_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    FOREIGN KEY (club_id)
        REFERENCES clubs(id)
        ON DELETE CASCADE,

    FOREIGN KEY (subgroup_id)
        REFERENCES club_subgroups(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_club_messages_club ON club_messages(club_id);
CREATE INDEX idx_club_messages_subgroup ON club_messages(subgroup_id);
CREATE INDEX idx_club_messages_sender ON club_messages(sender_id);

--------------------------------------------------
-- RIDES 
--------------------------------------------------

CREATE TABLE rides (
    id BIGSERIAL PRIMARY KEY,
    uuid VARCHAR(100) UNIQUE NOT NULL,

    created_by BIGINT NOT NULL,

    club_id BIGINT,

    title VARCHAR(150) NOT NULL,
    ride_type VARCHAR(10) NOT NULL,
    route_type VARCHAR(20) NOT NULL,

    description TEXT,

    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,

    max_riders INT CHECK (max_riders > 0),

    captain_id BIGINT,

    visibility VARCHAR(20) DEFAULT 'PUBLIC'
        CHECK (visibility IN ('PUBLIC', 'PRIVATE')),

    status VARCHAR(20) DEFAULT 'UPCOMING',

    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE CASCADE,

    FOREIGN KEY (captain_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    FOREIGN KEY (club_id)
        REFERENCES clubs(id)
        ON DELETE SET NULL

);

CREATE INDEX idx_rides_status ON rides(status);
CREATE INDEX idx_rides_start_time ON rides(start_time);

--------------------------------------------------
-- RIDE LOCATIONS
--------------------------------------------------

CREATE TABLE ride_locations (
    id BIGSERIAL PRIMARY KEY,

    ride_id BIGINT NOT NULL,

    location_type VARCHAR(20)
        CHECK (location_type IN ('START','END','CHECKPOINT')),

    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,

    name VARCHAR(255),

    sequence INT,

    recorded_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE
);

--------------------------------------------------
-- RIDE INVITES
--------------------------------------------------

CREATE TABLE ride_invitations (
    id BIGSERIAL PRIMARY KEY,

    ride_id BIGINT NOT NULL,
    invitee_id BIGINT NOT NULL,
    inviter_id BIGINT NOT NULL,

    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','ACCEPTED','REJECTED')),

    created_at TIMESTAMP DEFAULT now(),
    responded_at TIMESTAMP,

    UNIQUE (ride_id, invitee_id),

    FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    FOREIGN KEY (invitee_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    FOREIGN KEY (inviter_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_ride_invitations_ride ON ride_invitations(ride_id);
CREATE INDEX idx_ride_invitations_invitee ON ride_invitations(invitee_id);

--------------------------------------------------
-- RIDE PARTICIPANTS
--------------------------------------------------

CREATE TABLE ride_participants (
    id BIGSERIAL PRIMARY KEY,

    ride_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    role VARCHAR(20),

    rsvp_status VARCHAR(20),

    ride_state VARCHAR(30),

    joined_at TIMESTAMP DEFAULT now(),
    partial_started_at TIMESTAMP,
    arrived_at_start_at TIMESTAMP,
    state_updated_at TIMESTAMP,
    return_started_at TIMESTAMP,
    return_completed_at TIMESTAMP,
    return_ride_duration_seconds BIGINT,
    left_at TIMESTAMP,

    UNIQUE (ride_id, user_id),

    FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_rp_ride ON ride_participants(ride_id);
CREATE INDEX idx_rp_user ON ride_participants(user_id);

--------------------------------------------------
-- RIDE GROUPS (main group + subgroups)
--------------------------------------------------

CREATE TABLE ride_groups (
    id BIGSERIAL PRIMARY KEY,

    uuid VARCHAR(100) UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    ride_id BIGINT NOT NULL,

    parent_group_id BIGINT,

    name VARCHAR(150),

    visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC'
        CHECK (visibility IN ('PUBLIC','PRIVATE')),

    members_can_send_messages BOOLEAN NOT NULL DEFAULT TRUE,

    members_can_add_members BOOLEAN NOT NULL DEFAULT FALSE,

    admins_approve_members BOOLEAN NOT NULL DEFAULT TRUE,

    pre_ride_meeting_point VARCHAR(255),

    pre_ride_start_location TEXT,

    pre_ride_end_location TEXT,

    pre_ride_meeting_point_location TEXT,

    pre_ride_fuel_stops VARCHAR(255),

    pre_ride_checkpoints TEXT,

    pre_ride_checkpoint_locations TEXT,

    pre_ride_rules TEXT,

    pre_ride_notes TEXT,

    pre_ride_updated_at TIMESTAMP,

    created_by BIGINT NOT NULL,

    created_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    FOREIGN KEY (parent_group_id)
        REFERENCES ride_groups(id)
        ON DELETE CASCADE,

    FOREIGN KEY (created_by)
    REFERENCES users(id)
        ON DELETE CASCADE
);

--------------------------------------------------
-- GROUP MEMBERS
--------------------------------------------------

CREATE TABLE group_members (
    id BIGSERIAL PRIMARY KEY,

    group_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    role VARCHAR(20),

    joined_at TIMESTAMP DEFAULT now(),

    UNIQUE(group_id, user_id),

    FOREIGN KEY (group_id)
        REFERENCES ride_groups(id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

--------------------------------------------------
-- GROUP JOIN REQUESTS
--------------------------------------------------

CREATE TABLE group_join_requests (
    id BIGSERIAL PRIMARY KEY,

    group_id BIGINT NOT NULL,

    user_id BIGINT NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','APPROVED','REJECTED')),

    created_at TIMESTAMP NOT NULL DEFAULT now(),

    updated_at TIMESTAMP NOT NULL DEFAULT now(),

    UNIQUE (group_id, user_id, status),

    FOREIGN KEY (group_id)
        REFERENCES ride_groups(id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

--------------------------------------------------
-- RIDE MESSAGES
--------------------------------------------------

-- CREATE TABLE ride_messages (
--     id BIGSERIAL PRIMARY KEY,
--     ride_id BIGINT NOT NULL,
--     sender_id BIGINT NOT NULL,
--     message TEXT NOT NULL,
--     sent_at TIMESTAMP DEFAULT now(),
--     FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
--     FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
-- );

-- CREATE INDEX idx_rm_ride ON ride_messages(ride_id);
-- CREATE INDEX idx_rm_time ON ride_messages(sent_at);

--------------------------------------------------
-- GROUP MESSAGES
--------------------------------------------------

CREATE TABLE group_messages (
    id BIGSERIAL PRIMARY KEY,

    uuid VARCHAR(100) UNIQUE NOT NULL DEFAULT gen_random_uuid(),

    group_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,

    message TEXT,

    message_type VARCHAR(20) DEFAULT 'TEXT'
        CHECK (message_type IN ('TEXT','IMAGE','VIDEO','SYSTEM')),

    media_url TEXT,          -- image/video URL
    media_thumbnail TEXT,    -- preview thumbnail
    media_size BIGINT,
    media_duration INT,      -- video duration (sec)

    reply_to_message_id BIGINT,

    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (group_id)
        REFERENCES ride_groups(id)
        ON DELETE CASCADE,

    FOREIGN KEY (sender_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    FOREIGN KEY (reply_to_message_id)
        REFERENCES group_messages(id)
        ON DELETE SET NULL
);

CREATE INDEX idx_gm_group ON group_messages(group_id);
CREATE INDEX idx_gm_created_at ON group_messages(created_at);
CREATE INDEX idx_gm_sender ON group_messages(sender_id);

--------------------------------------------------
-- MESSAGAE READ STATUS
--------------------------------------------------

CREATE TABLE message_reads (
    id BIGSERIAL PRIMARY KEY,

    message_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    read_at TIMESTAMP DEFAULT now(),

    UNIQUE(message_id, user_id),

    FOREIGN KEY (message_id)
        REFERENCES group_messages(id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_mr_message ON message_reads(message_id);
CREATE INDEX idx_mr_user ON message_reads(user_id);

----------------------------------------------
-- MESSAGAE REACTIONs
----------------------------------------------

CREATE TABLE message_reactions (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT,
    user_id BIGINT,
    reaction VARCHAR(10),

    UNIQUE(message_id, user_id, reaction)
);

--------------------------------------------------
-- RIDE RULES
--------------------------------------------------

CREATE TABLE ride_rules (
    id BIGSERIAL PRIMARY KEY,
    
    ride_id BIGINT NOT NULL,
    
    rule TEXT NOT NULL,
    
    rule_order INT DEFAULT 0,  -- ordering support
    
    created_by BIGINT NOT NULL,
    
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_rr_ride ON ride_rules(ride_id);
CREATE INDEX idx_rr_created_by ON ride_rules(created_by);

------------------------------------------------
-- RIDE LIVE LOCATIONS
------------------------------------------------

CREATE TABLE ride_live_locations (
    id BIGSERIAL PRIMARY KEY,

    ride_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,

    recorded_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_live_location_ride ON ride_live_locations(ride_id);
CREATE INDEX idx_live_location_user ON ride_live_locations(user_id);
CREATE INDEX idx_live_location_time ON ride_live_locations(recorded_at);

--------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------

CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    type VARCHAR(50) NOT NULL,

    title VARCHAR(200),
    message TEXT,

    reference_id BIGINT,
    reference_type VARCHAR(50),

    is_read BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT now(),

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_notifications_user ON notifications(user_id);

--------------------------------------------------
-- BIKE MASTER
--------------------------------------------------

CREATE TABLE bike_master (
    id BIGSERIAL PRIMARY KEY,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    variant VARCHAR(150) NOT NULL,
    engine_cc INT,
    category VARCHAR(30),
    bike_type VARCHAR(100),
    tank_capacity NUMERIC(6,2),
    range_km INT,
    comfort_score INT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_bike_master_brand_model_variant UNIQUE (brand, model, variant)
);

CREATE INDEX idx_bike_master_brand ON bike_master(brand);
CREATE INDEX idx_bike_master_brand_model ON bike_master(brand, model);
CREATE INDEX idx_bike_master_active_verified ON bike_master(is_active, is_verified);

--------------------------------------------------
-- USER BIKES
--------------------------------------------------

CREATE TABLE user_bikes (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    bike_master_id BIGINT,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    variant VARCHAR(150),
    year INT,
    type VARCHAR(100),
    category VARCHAR(30),
    engine_cc INT,
    tank_capacity NUMERIC(6,2),
    range_km INT,
    comfort_score INT,
    is_primary BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (bike_master_id) REFERENCES bike_master(id) ON DELETE SET NULL
);

CREATE INDEX idx_ub_user ON user_bikes(user_id);
CREATE INDEX idx_user_bikes_bike_master ON user_bikes(bike_master_id);

--------------------------------------------------
-- USER ACHIEVEMENTS (Badges)
--------------------------------------------------

CREATE TABLE user_achievements (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    icon_name VARCHAR(50),
    earned_at TIMESTAMP DEFAULT now(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_ua_user ON user_achievements(user_id);

--------------------------------------------------
-- RIDE STATS
--------------------------------------------------

CREATE TABLE ride_stats (
    id BIGSERIAL PRIMARY KEY,
    ride_id VARCHAR(100) NOT NULL,
    user_id VARCHAR(100) NOT NULL,
    distance_km DOUBLE PRECISION NOT NULL,
    duration_minutes BIGINT NOT NULL,
    avg_speed DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_rs_ride ON ride_stats(ride_id);
CREATE INDEX idx_rs_user ON ride_stats(user_id);

--------------------------------------------------
-- FRIEND REQUESTS
--------------------------------------------------

CREATE TABLE friend_requests (
    id BIGSERIAL PRIMARY KEY,
    sender_id BIGINT NOT NULL,
    receiver_id BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED')),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),

    UNIQUE (sender_id, receiver_id),

    FOREIGN KEY (sender_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    FOREIGN KEY (receiver_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_fr_receiver ON friend_requests(receiver_id);

--------------------------------------------------
-- FRIENDSHIPS
--------------------------------------------------

CREATE TABLE friendships (
    user_id BIGINT NOT NULL,
    friend_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),

    PRIMARY KEY (user_id, friend_id),

    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    FOREIGN KEY (friend_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_fs_user ON friendships(user_id);
