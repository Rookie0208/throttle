package com.ridersclub.auth.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class OtpService {

    private final JavaMailSender mailSender;

    // In-memory store for OTPs with Expiration wrapper
    private static class OtpData {
        String otpCode;
        LocalDateTime expiryTime;

        OtpData(String otpCode, LocalDateTime expiryTime) {
            this.otpCode = otpCode;
            this.expiryTime = expiryTime;
        }
    }

    private final Map<String, OtpData> otpStore = new ConcurrentHashMap<>();

    @Autowired
    public OtpService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public String generateAndSendOtp(String email) {
        String otp = generateOtp();
        // OTP expires in 10 minutes
        otpStore.put(email, new OtpData(otp, LocalDateTime.now().plusMinutes(10)));
        sendEmail(email, otp);
        return otp;
    }

    public boolean verifyOtp(String email, String otp) {
        OtpData storedOtp = otpStore.get(email);
        if (storedOtp != null && storedOtp.otpCode.equals(otp)) {
            if (LocalDateTime.now().isBefore(storedOtp.expiryTime)) {
                otpStore.remove(email); // OTP is single-use
                log.info("OTP verified successfully for email: {}", email);
                return true;
            } else {
                otpStore.remove(email); // expired
                log.warn("Attempt to use expired OTP for email: {}", email);
            }
        }
        return false;
    }

    @Async
    protected void sendEmail(String to, String otp) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(to);
            message.setSubject("Your Throttle Verification Code");
            message.setText("Your OTP code for Throttle is: " + otp + "\n\nThis code will expire in 10 minutes.");
            mailSender.send(message);
            log.info("OTP successfully sent to {}", to);
        } catch (Exception e) {
            log.error("Failed to send OTP email to {}: {}", to, e.getMessage());
        }
    }

    private String generateOtp() {
        SecureRandom random = new SecureRandom();
        int num = random.nextInt(900000) + 100000; // 6 digit OTP
        return String.valueOf(num);
    }

    // Runs every 10 minutes to clear out expired OTPs from the map and free memory
    @Scheduled(fixedRate = 600000)
    public void cleanupExpiredOtps() {
        LocalDateTime now = LocalDateTime.now();
        int initialSize = otpStore.size();
        otpStore.entrySet().removeIf(entry -> now.isAfter(entry.getValue().expiryTime));
        int removedCount = initialSize - otpStore.size();
        if (removedCount > 0) {
            log.debug("Cleaned up {} expired OTPs from memory.", removedCount);
        }
    }
}
