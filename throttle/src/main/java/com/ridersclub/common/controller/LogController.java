package com.ridersclub.common.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/logs")

public class LogController {

    private static final String LOG_DIR = "logs";
    private static final String LOG_FILE = LOG_DIR + "/throttle_UI.log";
    private static final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS");

    @PostMapping
    public ResponseEntity<Void> receiveFrontendLog(@RequestBody Map<String, Object> logPayload) {
        String level = (String) logPayload.getOrDefault("level", "INFO");
        String message = (String) logPayload.getOrDefault("message", "");
        String time = LocalDateTime.now().format(formatter);

        String formattedLog = String.format("%s [%-5s] Frontend - %s\n", time, level, message);

        writeLogToFile(formattedLog);
        return ResponseEntity.ok().build();
    }

    private synchronized void writeLogToFile(String logMessage) {
        try {
            File dir = new File(LOG_DIR);
            if (!dir.exists()) {
                dir.mkdirs();
            }
            try (FileWriter writer = new FileWriter(LOG_FILE, true)) {
                writer.write(logMessage);
            }
        } catch (IOException e) {
            System.err.println("Failed to write frontend log: " + e.getMessage());
        }
    }
}
