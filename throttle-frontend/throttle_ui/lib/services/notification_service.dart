import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:throttle_ui/models/notification_model.dart';
import 'package:throttle_ui/services/auth_service.dart';

class NotificationService {
  static const String baseUrl = "http://localhost:8080/api/v1";
  static const String _eventEndpoint = "$baseUrl/notifications/events";
  static final List<Map<String, dynamic>> _pendingNotificationEvents = [];
  static final List<NotificationItem> _localNotifications = [];
  static final Set<String> _sentEventKeys = {};
  static int _nextLocalNotificationId = -1;

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

      final remoteNotifications = list == null || list.isEmpty
          ? <NotificationItem>[]
          : List<NotificationItem>.from(
              list.map((e) => NotificationItem.fromJson(e)),
            );

      return _mergeNotifications(remoteNotifications);
    }
      return _mergeNotifications(const []); // Return local notifications for non-200 responses
    } catch (e) {
      print("ERROR: $e");
      return _mergeNotifications(const []); // Return local notifications if error occurs
    }
  }

/// MARK AS READ / UNREAD
  Future<bool> markAsRead(int notificationId, bool read, String token) async {
    if (notificationId < 0) {
      final localIndex = _localNotifications.indexWhere(
        (item) => item.id == notificationId,
      );
      if (localIndex != -1) {
        _localNotifications[localIndex].unread = !read;
        return true;
      }
      return false;
    }

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

  Future<void> notifySubGroupCreated({
    String? token,
    required String subgroupName,
    String? rideName,
  }) async {
    await _queueNotificationEvent(
      token: token,
      type: "SUBGROUP_CREATED",
      title: "Subgroup created",
      message: rideName == null || rideName.isEmpty
          ? "Subgroup \"$subgroupName\" was created successfully."
          : "Subgroup \"$subgroupName\" was created for \"$rideName\".",
      dedupeKey: "subgroup_created::$subgroupName::$rideName",
      metadata: {"subgroupName": subgroupName, "rideName": rideName},
    );
  }

  Future<void> notifyAnnouncementPublished({
    String? token,
    required String groupName,
    required String announcementTitle,
  }) async {
    await _queueNotificationEvent(
      token: token,
      type: "ANNOUNCEMENT_PUBLISHED",
      title: "New announcement",
      message: "$announcementTitle was posted in $groupName.",
      dedupeKey: "announcement::$groupName::$announcementTitle",
      metadata: {
        "groupName": groupName,
        "announcementTitle": announcementTitle,
      },
    );
  }

  Future<void> notifyRideReminders({
    String? token,
    required String rideTitle,
    required DateTime startTime,
    String? rideId,
  }) async {
    final now = DateTime.now();
    final difference = startTime.difference(now);

    if (difference.inSeconds <= 0) return;

    if (difference.inHours <= 24) {
      await _queueNotificationEvent(
        token: token,
        type: "RIDE_STARTING_SOON_24H",
        title: "Upcoming ride",
        message: "\"$rideTitle\" starts in ${difference.inHours} hour${difference.inHours == 1 ? "" : "s"}.",
        dedupeKey: "ride_24h::${rideId ?? rideTitle}",
        metadata: {
          "rideId": rideId,
          "rideTitle": rideTitle,
          "startTime": startTime.toIso8601String(),
        },
      );
    }

    if (difference.inMinutes <= 120) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      final timeLeft = hours > 0
          ? "$hours hour${hours == 1 ? "" : "s"} ${minutes > 0 ? "$minutes min" : ""}".trim()
          : "$minutes min";

      await _queueNotificationEvent(
        token: token,
        type: "RIDE_STARTING_SOON_2H",
        title: "Ride starts soon",
        message: "\"$rideTitle\" starts in $timeLeft.",
        dedupeKey: "ride_2h::${rideId ?? rideTitle}",
        metadata: {
          "rideId": rideId,
          "rideTitle": rideTitle,
          "startTime": startTime.toIso8601String(),
        },
      );
    }
  }

  Future<void> notifyMeetingPointSelected({
    String? token,
    required String rideTitle,
    required String meetingPoint,
  }) async {
    await _queueNotificationEvent(
      token: token,
      type: "MEETING_POINT_SELECTED",
      title: "Meeting point selected",
      message: "Captain selected \"$meetingPoint\" for $rideTitle.",
      dedupeKey: "meeting_point::$rideTitle::$meetingPoint",
      metadata: {
        "rideTitle": rideTitle,
        "meetingPoint": meetingPoint,
      },
    );
  }

  Future<void> notifyPreRideInfoUpdated({
    String? token,
    required String rideTitle,
  }) async {
    await _queueNotificationEvent(
      token: token,
      type: "PRE_RIDE_UPDATED",
      title: "Pre-ride info updated",
      message: "Captain updated the pre-ride information for $rideTitle.",
      dedupeKey: "pre_ride_updated::$rideTitle::${DateTime.now().millisecondsSinceEpoch ~/ 60000}",
      metadata: {"rideTitle": rideTitle},
    );
  }

  Future<void> notifyFriendRequestSent({
    String? token,
    required String recipientName,
  }) async {
    await _queueNotificationEvent(
      token: token,
      type: "FRIEND_REQUEST_SENT",
      title: "Friend request sent",
      message: "Your friend request was sent to $recipientName.",
      dedupeKey: "friend_request::$recipientName",
      metadata: {"recipientName": recipientName},
    );
  }

  Future<void> notifyBadgeAchieved({
    String? token,
    required String badgeName,
  }) async {
    await _queueNotificationEvent(
      token: token,
      type: "BADGE_ACHIEVED",
      title: "New badge unlocked",
      message: "You earned the \"$badgeName\" badge.",
      dedupeKey: "badge::$badgeName",
      metadata: {"badgeName": badgeName},
    );
  }

  Future<void> notifyAccountVerified({
    String? token,
    required String email,
  }) async {
    await _queueNotificationEvent(
      token: token,
      type: "ACCOUNT_VERIFIED",
      title: "Account verified",
      message: "Your account for $email has been verified successfully.",
      dedupeKey: "account_verified::$email",
      metadata: {"email": email},
    );
  }

  List<Map<String, dynamic>> pendingNotificationEvents() {
    return List<Map<String, dynamic>>.from(_pendingNotificationEvents);
  }

  Future<void> _queueNotificationEvent({
    required String type,
    required String title,
    required String message,
    String? token,
    String? dedupeKey,
    Map<String, dynamic>? metadata,
  }) async {
    final eventKey = dedupeKey ?? "$type::$title::$message";
    if (_sentEventKeys.contains(eventKey)) return;

    _sentEventKeys.add(eventKey);

    final payload = {
      "type": type,
      "title": title,
      "message": message,
      "metadata": metadata ?? {},
      "createdAt": DateTime.now().toIso8601String(),
    };

    _pendingNotificationEvents.add(payload);
    _localNotifications.insert(
      0,
      NotificationItem(
        id: _nextLocalNotificationId--,
        title: title,
        desc: message,
        time: payload["createdAt"] as String,
        unread: true,
        type: type,
      ),
    );

    final resolvedToken = token ?? await AuthService.getToken();
    if (resolvedToken == null || resolvedToken.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(_eventEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $resolvedToken",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _pendingNotificationEvents.remove(payload);
      }
    } catch (_) {
      // Backend endpoint is not ready yet. Keep the event queued locally.
    }
  }

  List<NotificationItem> _mergeNotifications(
    List<NotificationItem> remoteNotifications,
  ) {
    final merged = <NotificationItem>[
      ..._localNotifications,
      ...remoteNotifications,
    ];

    final seen = <String>{};
    return merged.where((notification) {
      final key =
          "${notification.type}::${notification.title}::${notification.desc}";
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}
