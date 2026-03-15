import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:throttle_ui/models/notification_model.dart';

class NotificationService {

  static const String baseUrl = "http://localhost:8080/api/v1";

  Future<List<NotificationItem>> fetchNotifications() async {
    try {

      final response = await http.get(
        Uri.parse("$baseUrl/notifications/my"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data == null || data["data"] == null || data["data"].isEmpty) {
          return _dummyNotifications();
        }

        List list = data["data"];

        return list
            .map((e) => NotificationItem.fromJson(e))
            .toList();
      }

      return _dummyNotifications();

    } catch (e) {
      return _dummyNotifications();
    }
  }

  /// Dummy fallback
  List<NotificationItem> _dummyNotifications() {
    return [
      NotificationItem(
        id: 1,
        type: "invite",
        icon: Icons.location_on,
        title: "Ride Invitation",
        desc: "Mike T. invited you to Sunday Mountain Run",
        time: "5m ago",
        unread: true,
      ),
      NotificationItem(
        id: 2,
        type: "join",
        icon: Icons.person_add,
        title: "Join Request",
        desc: "Chris M. wants to join Weekend Warriors",
        time: "20m ago",
        unread: true,
      ),
      NotificationItem(
        id: 3,
        type: "streak",
        icon: Icons.local_fire_department,
        title: "Streak Reminder",
        desc: "Don't break your 12-day streak! Go for a ride today.",
        time: "1h ago",
        unread: true,
      ),
      NotificationItem(
        id: 4,
        type: "competition",
        icon: Icons.emoji_events,
        title: "Competition Update",
        desc: "You moved to #3 in the February Miles Challenge!",
        time: "3h ago",
        unread: false,
      ),
      NotificationItem(
        id: 5,
        type: "complete",
        icon: Icons.check_circle,
        title: "Ride Complete",
        desc: "Great ride! You covered 68 miles in 2h 15m on Canyon Loop.",
        time: "Yesterday",
        unread: false,
      ),
    ];
  }
}