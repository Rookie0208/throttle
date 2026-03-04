# Start the Backend (Java Spring Boot)
echo "Starting Backend..."
cd throttle
nohup mvn spring-boot:run &

# Start the Frontend
echo "Starting Frontend..."
cd ../throttle-frontend/throttle_ui
nohup flutter run -d chrome --web-port=8081 &

# Start Docker Containers
echo "Starting Docker Containers..."
cd ../..
nohup docker-compose up -d &

echo "All systems are running!"