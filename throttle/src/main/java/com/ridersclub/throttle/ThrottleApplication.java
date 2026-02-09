package com.ridersclub.throttle;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.jdbc.autoconfigure.DataSourceAutoConfiguration;

@SpringBootApplication(
    exclude = { DataSourceAutoConfiguration.class },
    scanBasePackages = "com.ridersclub"
)
public class ThrottleApplication {

	public static void main(String[] args) {
		SpringApplication.run(ThrottleApplication.class, args);
	}

}
