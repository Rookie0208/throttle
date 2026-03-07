CREATE EXTENSION IF NOT EXISTS "pgcrypto";

--------------------------------------------------
-- USERS
--------------------------------------------------

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    uuid VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
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
    created_at TIMESTAMP DEFAULT now(),
    experience_years INT DEFAULT 0
);

CREATE INDEX idx_users_uuid ON users(uuid);

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

CREATE TABLE ride_invites (
    id BIGSERIAL PRIMARY KEY,

    ride_id BIGINT NOT NULL,
    invited_user_id BIGINT NOT NULL,
    invited_by BIGINT NOT NULL,

    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','ACCEPTED','REJECTED')),

    invited_at TIMESTAMP DEFAULT now(),
    responded_at TIMESTAMP,

    UNIQUE (ride_id, invited_user_id),

    FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    FOREIGN KEY (invited_user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    FOREIGN KEY (invited_by)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_invites_ride ON ride_invites(ride_id);
CREATE INDEX idx_invites_user ON ride_invites(invited_user_id);

--------------------------------------------------
-- RIDE PARTICIPANTS
--------------------------------------------------

CREATE TABLE ride_participants (
    id BIGSERIAL PRIMARY KEY,

    ride_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    role VARCHAR(20),

    rsvp_status VARCHAR(20),

    joined_at TIMESTAMP DEFAULT now(),
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
-- RIDE MESSAGES
--------------------------------------------------

CREATE TABLE ride_messages (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    message TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT now(),
    FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_rm_ride ON ride_messages(ride_id);
CREATE INDEX idx_rm_time ON ride_messages(sent_at);

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