package com.ridersclub.common.Utils;

public class NormalizeUtil {
    public static String lowerTrim(String value) {
        return value == null ? null : value.trim().toLowerCase();
    }

    public static String trim(String value) {
        return value == null ? null : value.trim();
    }
}
