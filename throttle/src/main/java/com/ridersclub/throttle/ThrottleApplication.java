package com.ridersclub.throttle;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableAsync;

import org.springframework.context.annotation.FilterType;
import org.springframework.context.annotation.ComponentScan.Filter;
import org.springframework.data.neo4j.repository.config.EnableNeo4jRepositories;
import com.ridersclub.friend.repository.neo4j.UserNodeRepository;

@EnableAsync
@EnableCaching
@EnableJpaRepositories(basePackages = { "com.ridersclub.user.repository", "com.ridersclub.ride.repository",
        "com.ridersclub.notification.repository", "com.ridersclub.auth.repository",
        "com.ridersclub.friend.repository", "com.ridersclub.bike.repository",
        "com.ridersclub.message.repository",
        "com.ridersclub.admin.repository" }, excludeFilters = @Filter(type = FilterType.ASSIGNABLE_TYPE, classes = UserNodeRepository.class))
@EnableNeo4jRepositories(basePackages = "com.ridersclub.friend.repository", includeFilters = @Filter(type = FilterType.ASSIGNABLE_TYPE, classes = UserNodeRepository.class))
@EntityScan(basePackages = { "com.ridersclub.user.entity", "com.ridersclub.ride.entity",
        "com.ridersclub.notification.entity", "com.ridersclub.auth.entity", "com.ridersclub.friend.entity",
        "com.ridersclub.message.entity", "com.ridersclub.bike.entity",
        "com.ridersclub.admin.entity" })
@SpringBootApplication(scanBasePackages = "com.ridersclub")
public class ThrottleApplication {

    public static void main(String[] args) {
        SpringApplication.run(ThrottleApplication.class, args);
    }

}
