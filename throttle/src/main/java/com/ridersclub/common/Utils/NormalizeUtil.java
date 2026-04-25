package com.ridersclub.common.Utils;

public class NormalizeUtil {
    public static String lowerTrim(String value) {
        return value == null ? null : value.trim().toLowerCase();
    }

    public static String trim(String value) {
        return value == null ? null : value.trim();
    }

    public static String capitalizeTrim(String value) {
        if (value == null || value.trim().isEmpty()) {
            return value == null ? null : "";
        }
        String[] words = value.trim().split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < words.length; i++) {
            String word = words[i];
            sb.append(word.substring(0, 1).toUpperCase())
              .append(word.substring(1).toLowerCase());
            if (i < words.length - 1) {
                sb.append(" ");
            }
        }
        return sb.toString();
    }
}
