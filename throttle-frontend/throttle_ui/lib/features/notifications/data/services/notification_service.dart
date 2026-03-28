import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:throttle_ui/features/notifications/data/models/notification_model.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/core/services/logger_service.dart';
import 'package:throttle_ui/core/constants/app_constants.dart';

class NotificationService {
  static String get baseUrl => AppConstants.baseUrl;
  static String get _eventEndpoint => "$baseUrl/notifications/events";
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
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data["data"];

        final remoteNotifications = list == null || list.isEmpty
            ? <NotificationItem>[]
            : List<NotificationItem>.from(
                list.map((e) => NotificationItem.fromJson(e)),
              );

        return _mergeNotifications(remoteNotifications);
      }

      Logger.warn(
        "Failed to fetch notifications: ${response.statusCode} ${response.body}",
      );
      return _mergeNotifications(const []);
    } catch (e) {
      Logger.error("Error fetching notifications: $e");
      return _mergeNotifications(const []);
    }
  }

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
        body: jsonEncode({"read": read}),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.error("Error updating notification read status: $e");
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

  Future<void> sendRideAnnouncement({
    required String token,
    required String rideUuid,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/rides/$rideUuid/announcement"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = response.body.isEmpty ? {} : jsonDecode(response.body);
      throw Exception(data["message"] ?? "Failed to send announcement");
    }
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
    final countdownLabel = _formatCountdown(difference);

    if (difference.inHours <= 24) {
      await _queueNotificationEvent(
        token: token,
        type: "RIDE_STARTING_SOON_24H",
        title: "Upcoming ride",
        message: "\"$rideTitle\" starts in $countdownLabel.",
        dedupeKey: "ride_24h::${rideId ?? rideTitle}",
        metadata: {
          "rideId": rideId,
          "rideTitle": rideTitle,
          "startTime": startTime.toIso8601String(),
        },
      );
    }

    if (difference.inMinutes <= 120) {
      await _queueNotificationEvent(
        token: token,
        type: "RIDE_STARTING_SOON_2H",
        title: "Ride starts soon",
        message: "\"$rideTitle\" starts in $countdownLabel.",
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
      dedupeKey:
          "pre_ride_updated::$rideTitle::${DateTime.now().millisecondsSinceEpoch ~/ 60000}",
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

  String _formatCountdown(Duration difference) {
    final totalMinutes = difference.inMinutes;
    if (totalMinutes <= 0) {
      return "less than a minute";
    }
    if (totalMinutes < 60) {
      return "$totalMinutes min";
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return "$hours hour${hours == 1 ? "" : "s"}";
    }
    return "$hours hour${hours == 1 ? "" : "s"} $minutes min";
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
    final persistedKeys = remoteNotifications
        .map(_notificationContentKey)
        .toSet();

    final pendingLocalNotifications = _localNotifications.where((notification) {
      return !persistedKeys.contains(_notificationContentKey(notification));
    });

    final merged = <NotificationItem>[
      ...pendingLocalNotifications,
      ...remoteNotifications,
    ];

    merged.sort((a, b) => b.time.compareTo(a.time));
    return merged;
  }

  String _notificationContentKey(NotificationItem notification) {
    return "${notification.type}::${notification.title}::${notification.desc}";
  }
}
