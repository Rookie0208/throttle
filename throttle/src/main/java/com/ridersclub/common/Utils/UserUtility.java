package com.ridersclub.common.Utils;

import java.util.UUID;

public class UserUtility {
    // UUID v4 generator with prefix
    public static String generateUUID(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 20).toUpperCase();
    }
}
