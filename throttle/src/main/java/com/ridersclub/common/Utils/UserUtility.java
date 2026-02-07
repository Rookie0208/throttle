package com.ridersclub.common.Utils;

import java.util.UUID;

public class UserUtility {
    // UUID v4 generator with prefix
    public static String generateUserId(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }
}
