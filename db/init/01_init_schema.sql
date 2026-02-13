-- USERS TABLE
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- RIDES TABLE
CREATE TABLE rides (
    id BIGSERIAL PRIMARY KEY,
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

-- RIDE MEMBERS TABLE
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

-- RIDE LOCATIONS TABLE
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

-- INDEXES
CREATE INDEX idx_ride_members_ride ON ride_members(ride_id);
CREATE INDEX idx_ride_members_user ON ride_members(user_id);

CREATE INDEX idx_ride_locations_ride ON ride_locations(ride_id);
CREATE INDEX idx_ride_locations_user ON ride_locations(user_id);
CREATE INDEX idx_ride_locations_time ON ride_locations(recorded_at);
