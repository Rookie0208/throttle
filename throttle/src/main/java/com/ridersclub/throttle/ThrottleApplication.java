package com.ridersclub.throttle;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.jdbc.autoconfigure.DataSourceAutoConfiguration;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@EnableJpaRepositories(basePackages = "com.ridersclub.user.repository")
@EntityScan(basePackages = "com.ridersclub.user.entity")
@SpringBootApplication(
		// exclude = { DataSourceAutoConfiguration.class },
		scanBasePackages = "com.ridersclub")
public class ThrottleApplication {

	public static void main(String[] args) {
		SpringApplication.run(ThrottleApplication.class, args);
	}

}
