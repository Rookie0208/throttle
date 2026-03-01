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
-- GROUPS (Parent of rides)
--------------------------------------------------

CREATE TABLE groups (
    id BIGSERIAL PRIMARY KEY,
    uuid VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_groups_uuid ON groups(uuid);
CREATE INDEX idx_groups_created_by ON groups(created_by);

--------------------------------------------------
-- GROUP MEMBERS
--------------------------------------------------

CREATE TABLE group_members (
    id BIGSERIAL PRIMARY KEY,
    group_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) DEFAULT 'MEMBER'
        CHECK (role IN ('ADMIN', 'MEMBER')),
    joined_at TIMESTAMP DEFAULT now(),
    UNIQUE (group_id, user_id),
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_gm_group ON group_members(group_id);
CREATE INDEX idx_gm_user ON group_members(user_id);

--------------------------------------------------
-- RIDES
--------------------------------------------------

CREATE TABLE rides (
    id BIGSERIAL PRIMARY KEY,
    uuid VARCHAR(100) UNIQUE NOT NULL,
    group_id BIGINT NOT NULL,
    created_by BIGINT NOT NULL,
    title VARCHAR(150) NOT NULL,
    ride_type VARCHAR(10) NOT NULL,
    description TEXT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    start_location VARCHAR(255) NOT NULL,
    end_location VARCHAR(255) NOT NULL,
    start_lat DOUBLE PRECISION NOT NULL,
    start_lng DOUBLE PRECISION NOT NULL,
    end_lat DOUBLE PRECISION NOT NULL,
    end_lng DOUBLE PRECISION NOT NULL,
    -- ride_datetime TIMESTAMP NOT NULL,
    max_riders INT CHECK (max_riders > 0),
    captain_id VARCHAR(100),
    visibility VARCHAR(20) DEFAULT 'PUBLIC'
        CHECK (visibility IN ('PUBLIC', 'PRIVATE')),
    status VARCHAR(20) DEFAULT 'UPCOMING'
        CHECK (status IN ('UPCOMING', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_rides_group ON rides(group_id);
CREATE INDEX idx_rides_datetime ON rides(ride_datetime);
CREATE INDEX idx_rides_status ON rides(status);

--------------------------------------------------
-- RIDE INVITES
--------------------------------------------------

CREATE TABLE ride_invites (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL,
    invited_user_id BIGINT NOT NULL,
    invited_by BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED')),
    invited_at TIMESTAMP DEFAULT now(),
    responded_at TIMESTAMP,
    UNIQUE (ride_id, invited_user_id),
    FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
    FOREIGN KEY (invited_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE CASCADE
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
    role VARCHAR(20) DEFAULT 'RIDER'
        CHECK (role IN ('ORGANIZER', 'RIDER')),
    rsvp_status VARCHAR(20) DEFAULT 'CONFIRMED'
        CHECK (rsvp_status IN ('CONFIRMED', 'MAYBE', 'DECLINED')),
    joined_at TIMESTAMP DEFAULT now(),
    UNIQUE (ride_id, user_id),
    FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
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