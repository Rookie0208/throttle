-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

--------------------------------------------------
-- USERS TABLE
--------------------------------------------------

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
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

CREATE INDEX idx_users_public_id ON users(public_id);

--------------------------------------------------
-- RIDES TABLE
--------------------------------------------------

CREATE TABLE rides (
    id BIGSERIAL PRIMARY KEY,
    public_id UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,

    title VARCHAR(150) NOT NULL,
    description TEXT,

    start_location VARCHAR(255),
    end_location VARCHAR(255),
    start_time TIMESTAMP NOT NULL,

    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),

    CONSTRAINT fk_ride_creator
        FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_rides_public_id ON rides(public_id);
CREATE INDEX idx_rides_creator ON rides(created_by);

--------------------------------------------------
-- RIDE MEMBERS (Many-to-Many)
--------------------------------------------------

CREATE TABLE ride_members (
    id BIGSERIAL PRIMARY KEY,
    ride_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    joined_at TIMESTAMP DEFAULT now(),

    CONSTRAINT fk_rm_ride
        FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_rm_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_ride_user UNIQUE (ride_id, user_id)
);

CREATE INDEX idx_ride_members_ride ON ride_members(ride_id);
CREATE INDEX idx_ride_members_user ON ride_members(user_id);

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

    CONSTRAINT fk_rl_ride
        FOREIGN KEY (ride_id)
        REFERENCES rides(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_rl_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_ride_locations_ride ON ride_locations(ride_id);
CREATE INDEX idx_ride_locations_user ON ride_locations(user_id);
CREATE INDEX idx_ride_locations_time ON ride_locations(recorded_at);