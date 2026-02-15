# 🚀 Throttle - Ride Planning Mobile App

Throttle is a ride planning and management mobile application that allows users to create solo or group rides with route details, difficulty levels, and scheduling options.

The project consists of:

- 📱 Flutter Mobile App (Frontend)
- ☕ Spring Boot REST API (Backend)
- 🔐 JWT-based Authentication
- 🗄 Database (MySQL / PostgreSQL)

---

# 📦 Project Architecture

Throttle/
│
├── throttle_ui/              → Flutter Mobile App
│
└── throttle_backend/         → Spring Boot Backend
     ├── controller/
     ├── service/
     ├── repository/
     ├── model/
     ├── security/
     └── config/

---

# 📱 Flutter Frontend

## ✨ Features

- Onboarding screen
- Login & Signup (JWT authentication)
- Dashboard (List of rides)
- Create Ride screen
- Navigation using named routes
- Material 3 UI
- Clean theme configuration

---

## 📂 Folder Structure (Flutter)

lib/
│
├── main.dart
├── screens/
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── dashboard_screen.dart
│   └── create_ride_screen.dart
│
├── models/
├── services/
└── utils/

---

## 🛠 Requirements

- Flutter SDK (>= 3.x)
- Dart SDK
- Android Studio / VS Code
- Emulator or Physical Device

---

## ▶️ How to Run Flutter App

1. Navigate to project folder:
-> cd throttle_ui (parallel to pubspec.yaml file)
-> flutter run


---

# ☕ Spring Boot Backend

## ✨ Features

- User Registration
- User Login
- JWT Authentication
- Create Ride API
- Get Rides API
- Role-based access
- Global Exception Handling

---

## 📂 Backend Structure

src/main/java/com/throttle/

The folder structure is based on monolithic architure as a whole but internally divided into micro service architecture.
---

## 🛠 Requirements

- Java 17+
- Maven
- MySQL / PostgreSQL
- Postman (for API testing)

---

## ⚙️ Configure Database

Update `application.properties`:


---

## ▶️ Run Backend

1. Navigate to backend folder:
-> cd throttle

2. Build project:
-> mvn clean package

3. Run project:
-> mvn spring-boot:run

Backend will start at:
http://localhost:8080
