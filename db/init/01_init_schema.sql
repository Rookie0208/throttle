
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    city VARCHAR(100),
    bike_type VARCHAR(50),
    bio TEXT,
    experience_years INT,
    emergency_contact VARCHAR(20),
    created_at TIMESTAMP DEFAULT now()
);
