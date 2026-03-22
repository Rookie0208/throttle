import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:throttle_ui/models/notification_model.dart';

class NotificationService {
  static const String baseUrl = "http://localhost:8080/api/v1";

  Future<List<NotificationItem>> fetchNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/notifications/my"),
        headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      );
      print("url : "+"$baseUrl/notifications/my");
      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("PARSED DATA: $data");
        // If there is no "data" or it's empty, return an empty list
        final list = data["data"];

      if (list == null || list.isEmpty) {
        return [];
      }

      return List<NotificationItem>.from(
        list.map((e) => NotificationItem.fromJson(e)),
      );
    }
      return []; // Return empty list for non-200 responses
    } catch (e) {
      print("ERROR: $e");
      return []; // Return empty list if error occurs
    }
  }

/// MARK AS READ / UNREAD
  Future<bool> markAsRead(int notificationId, bool read, String token) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/notifications/$notificationId/read"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "read": read, // true = mark read, false = mark unread
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
