package com.ridersclub.config;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.File;

@Component
public class LoggingInitializer {
    private static final Logger logger = LoggerFactory.getLogger(LoggingInitializer.class);
    private static final String LOG_DIR = "logs"; // relative to working directory

    @PostConstruct
    public void ensureLogDirectory() {
        File dir = new File(LOG_DIR);
        if (!dir.exists()) {
            boolean created = dir.mkdirs();
            if (created) {
                logger.info("Created log directory: {}", dir.getAbsolutePath());
            } else {
                logger.warn("Could not create log directory: {}", dir.getAbsolutePath());
            }
        } else {
            logger.debug("Log directory already exists: {}", dir.getAbsolutePath());
        }
    }
}
