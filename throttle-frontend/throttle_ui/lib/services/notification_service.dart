import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:throttle_ui/models/notification_model.dart';
import 'package:throttle_ui/services/logger_service.dart';
import 'package:throttle_ui/utils/constants.dart';

class NotificationService {
  static String get baseUrl => AppConstants.baseUrl;

  Future<List<NotificationItem>> fetchNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/notifications/my"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data["data"];

        if (list == null || list.isEmpty) {
          return [];
        }

        return List<NotificationItem>.from(
          list.map((e) => NotificationItem.fromJson(e)),
        );
      }
      Logger.warn(
        "Failed to fetch notifications: ${response.statusCode} ${response.body}",
      );
      return [];
    } catch (e) {
      Logger.error("Error fetching notifications: $e");
      return [];
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
      Logger.error("Error updating notification read status: $e");
      return false;
    }
  }
}
