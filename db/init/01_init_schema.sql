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
-- RIDES 
--------------------------------------------------

CREATE TABLE rides (
    id BIGSERIAL PRIMARY KEY,
    uuid VARCHAR(100) UNIQUE NOT NULL,

    created_by BIGINT NOT NULL,

    title VARCHAR(150) NOT NULL,
    ride_type VARCHAR(10) NOT NULL,

    route_type VARCHAR(20) NOT NULL,

    description TEXT,

    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,

    start_location VARCHAR(255) NOT NULL,
    end_location VARCHAR(255) NOT NULL,

    start_lat DOUBLE PRECISION NOT NULL,
    start_lng DOUBLE PRECISION NOT NULL,
    end_lat DOUBLE PRECISION NOT NULL,
    end_lng DOUBLE PRECISION NOT NULL,

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
        ON DELETE SET NULL
);

CREATE INDEX idx_rides_status ON rides(status);
CREATE INDEX idx_rides_start_time ON rides(start_time);

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

--------------------------------------------------
-- RIDE LOCATIONS (Live tracking)
--------------------------------------------------

CREATE TABLE ride_locations (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    recorded_at TIMESTAMP DEFAULT now(),
    FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_rl_ride ON ride_locations(ride_id);
CREATE INDEX idx_rl_time ON ride_locations(recorded_at);

--------------------------------------------------
-- USER FOLLOWS
--------------------------------------------------

CREATE TABLE user_follows (
    id BIGSERIAL PRIMARY KEY,
    follower_id BIGINT NOT NULL,
    following_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    UNIQUE (follower_id, following_id),
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_uf_follower ON user_follows(follower_id);
CREATE INDEX idx_uf_following ON user_follows(following_id);

--------------------------------------------------
-- USER BIKES
--------------------------------------------------

CREATE TABLE user_bikes (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INT,
    type VARCHAR(100),
    engine_cc INT,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT now(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_ub_user ON user_bikes(user_id);

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