package com.ridersclub.throttle;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableAsync;

@EnableAsync
@EnableJpaRepositories(basePackages = {"com.ridersclub.user.repository", "com.ridersclub.ride.repository"})
@EntityScan(basePackages = "com.ridersclub.user.entity, com.ridersclub.ride.entity")
@SpringBootApplication(scanBasePackages = "com.ridersclub")
public class ThrottleApplication {

    public static void main(String[] args) {
        SpringApplication.run(ThrottleApplication.class, args);
    }

}
