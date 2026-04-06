import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:throttle_ui/features/notifications/data/models/notification_model.dart';
import 'package:throttle_ui/features/groups/presentation/screens/group_chat_screen.dart';
import 'package:throttle_ui/features/notifications/presentation/screens/notification_screen.dart';
import 'package:throttle_ui/features/notifications/data/services/notification_service.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/core/constants/app_constants.dart';
import 'package:throttle_ui/core/utils/string_extensions.dart';
import 'package:throttle_ui/core/services/location_service.dart';
import 'package:throttle_ui/core/services/weather_service.dart';
import 'package:throttle_ui/core/services/logger_service.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/features/rides/presentation/screens/live_ride_screen.dart';
import 'package:throttle_ui/features/rides/presentation/screens/ride_start_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String token;
  const DashboardScreen({super.key, this.userData, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profileData;
  String? _cityName;
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  int unreadNotificationCount = 0;
  List<NotificationItem> _notifications = [];
  NotificationItem? _dashboardAnnouncement;
  String? _userUuid;
  StompClient? _notificationClient;

  Map<String, dynamic> get _userData =>
      _profileData ?? widget.userData ?? const {};

  Map<String, dynamic>? _mapValue(String key) {
    final value = _userData[key];
    return value is Map<String, dynamic> ? value : null;
  }

  List<Map<String, dynamic>> _mapListValue(String key) {
    final value = _userData[key];
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  String _cleanSubtitle(Map<String, dynamic>? ride) {
    final rawSubtitle = ride?['subtitle']?.toString() ?? "";
    return rawSubtitle.contains("•")
        ? rawSubtitle.split("•").skip(1).join("•").trim()
        : rawSubtitle;
  }

  DateTime? _rideStartTime(Map<String, dynamic>? ride) {
    final raw = ride?['startTime']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _upcomingRideDateLabel(Map<String, dynamic>? ride) {
    final startTime = _rideStartTime(ride);
    if (startTime == null) {
      return _cleanSubtitle(ride);
    }
    final month = startTime.month.toString().padLeft(2, '0');
    final day = startTime.day.toString().padLeft(2, '0');
    return "$day/$month/${startTime.year}";
  }

  Future<void> _openRideGroup(
    Map<String, dynamic> ride, {
    String rideStatus = "SCHEDULED",
  }) async {
    final group = {
      "uuid": ride["groupUuid"] ?? ride["uuid"] ?? ride["id"],
      "id": ride["groupUuid"] ?? ride["uuid"] ?? ride["id"],
      "rideUuid": ride["uuid"] ?? ride["id"],
      "name": ride["title"] ?? "Ride",
      "title": ride["title"] ?? "Ride",
      "status": rideStatus == "CANCELLED" || rideStatus == "COMPLETED"
          ? "archive"
          : "active",
      "rideStatus": rideStatus,
      "description": ride["description"] ?? _cleanSubtitle(ride),
      "visibility": ride["visibility"] ?? "PUBLIC",
      "createdByName": ride["createdByName"],
      "createdAt": ride["createdAt"],
      "myRole": ride["myRole"],
      "members": <Map<String, dynamic>>[],
    };

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatScreen(group: group, token: widget.token),
      ),
    );
    await _refreshProfileData();
  }

  String _sectionHeading(Map<String, dynamic>? ride) {
    final subtitle = ride?['subtitle']?.toString().toUpperCase() ?? "";
    if (subtitle.contains("IN PROGRESS")) {
      return "In Progress";
    }
    return "Today's Plan";
  }

  String _rideStatusForDashboard({
    required Map<String, dynamic>? todayRide,
    required Map<String, dynamic>? todayPlanRide,
  }) {
    if (todayRide != null) {
      return "ACTIVE";
    }
    final rawStatus =
        (todayPlanRide?["status"] ?? todayPlanRide?["rideStatus"] ?? "")
            .toString()
            .toUpperCase();
    if (rawStatus.isNotEmpty) return rawStatus;
    return "SCHEDULED";
  }

  String _normalizedRideStatus(Map<String, dynamic>? ride) {
    final rawStatus = (ride?["rideStatus"] ?? ride?["status"] ?? "")
        .toString()
        .toUpperCase();
    if (rawStatus.isNotEmpty) return rawStatus;
    return "SCHEDULED";
  }

  bool _isStartedRideStatus(String status) {
    return {
      "PARTIAL_STARTED",
      "READY_TO_START",
      "ACTIVE",
      "IN_PROGRESS",
      "COMPLETED",
      "CANCELLED",
    }.contains(status.toUpperCase());
  }

  String _rideLocationLabel(Map<String, dynamic>? ride) {
    final locations = ride?["locations"];
    if (locations is List && locations.isNotEmpty) {
      final first = locations.first;
      if (first is Map && first["name"] != null) {
        return first["name"].toString();
      }
    }
    return (ride?["meetingPoint"] ??
            ride?["startLocation"] ??
            ride?["location"] ??
            "Start point")
        .toString();
  }

  int _rideMemberCount(Map<String, dynamic>? ride) {
    final riders = ride?["riders"];
    if (riders is int) return riders;
    final maxRiders = ride?["maxRiders"];
    if (maxRiders is int) return maxRiders;
    return int.tryParse((maxRiders ?? riders ?? 0).toString()) ?? 0;
  }

  Future<void> _openRideConsoleFromDashboard(
    Map<String, dynamic> ride, {
    required String rideStatus,
  }) async {
    final normalizedStatus = rideStatus.toUpperCase();
    final title = (ride["title"] ?? "Ride").toString();

    final Widget target = normalizedStatus == "ACTIVE"
        ? LiveRideScreen(
            groupName: title,
            onEndRide: () {},
            token: widget.token,
            rideUuid: (ride["uuid"] ?? ride["id"]).toString(),
          )
        : RideStartScreen(
            groupName: title,
            rideDate: _upcomingRideDateLabel(ride),
            rideTime: ride["time"]?.toString() ?? "",
            location: _rideLocationLabel(ride),
            memberCount: _rideMemberCount(ride),
            token: widget.token,
            rideUuid: (ride["uuid"] ?? ride["id"]).toString(),
          );

    await Navigator.push(context, MaterialPageRoute(builder: (_) => target));
    await _refreshProfileData();
  }

  @override
  void initState() {
    super.initState();
    _refreshProfileData();
    _fetchLocationAndWeather();
    _initializeNotifications();
    _syncUpcomingRideReminderNotifications();
  }

  Future<void> _refreshProfileData() async {
    final freshProfile = await UserService.getMe();
    if (!mounted || freshProfile == null) return;
    setState(() {
      _profileData = freshProfile;
    });
  }

  @override
  void dispose() {
    _notificationClient?.deactivate();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _resolveUserUuid();
    await _fetchUnreadNotificationCount();
    _connectNotificationSocket();
  }

  Future<void> _resolveUserUuid() async {
    final widgetUserId = widget.userData?['id'];
    if (widgetUserId is String && widgetUserId.isNotEmpty) {
      _userUuid = widgetUserId;
      return;
    }

    final me = await UserService.getMe();
    final userId = me?['id'];
    if (userId is String && userId.isNotEmpty) {
      _userUuid = userId;
    }
  }

  void _connectNotificationSocket() {
    if (_userUuid == null || widget.token.isEmpty) {
      return;
    }

    final socketUrl = AppConstants.baseUrl
        .replaceAll('http://', 'ws://')
        .replaceAll('https://', 'wss://')
        .replaceAll('/api/v1', '/ws-friends');

    _notificationClient?.deactivate();
    _notificationClient = StompClient(
      config: StompConfig(
        url: socketUrl,
        webSocketConnectHeaders: {'Authorization': 'Bearer ${widget.token}'},
        onConnect: (StompFrame frame) {
          _notificationClient?.subscribe(
            destination: '/topic/notifications/$_userUuid',
            callback: (StompFrame frame) {
              _fetchUnreadNotificationCount();
            },
          );
        },
        onWebSocketError: (dynamic error) {
          Logger.warn('Notification websocket error: $error');
        },
        onStompError: (StompFrame frame) {
          Logger.warn('Notification STOMP error: ${frame.body}');
        },
      ),
    );
    _notificationClient?.activate();
  }

  Future<void> _fetchLocationAndWeather() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final city = await LocationService.getCityName(
          position.latitude,
          position.longitude,
        );

        final weather = await WeatherService.getCurrentWeather(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() {
            _cityName = city;
            _weatherData = weather;
            _isLoadingWeather = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingWeather = false;
          });
        }
      }
    } catch (e) {
      Logger.error("Error in _fetchLocationAndWeather: $e");
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  String _getGreeting() {
    var now = DateTime.now();
    var hour = now.hour;
    var dayIndex =
        now.day %
        3; // Rotates options daily to prevent UI flickering on rebuilds

    if (4 < hour && hour < 12) {
      const options = [
        "Kickstart your day! ⚡",
        "Wake up and twist the throttle! 🏍️",
        "Time to burn morning rubber! 💨",
      ];
      return options[dayIndex];
    } else if (hour < 17) {
      const options = [
        "Drop a gear and disappear! 🚀",
        "Sun's up, visors down! 🕶️",
        "Keep the shiny side up! ✨",
      ];
      return options[dayIndex];
    } else if (hour < 20) {
      const options = [
        "Chasing the sunset? 🌇",
        "Evening throttle therapy! 😌",
        "Golden hour cruise calling! 🌞",
      ];
      return options[dayIndex];
    } else {
      const options = [
        "Night rider mode activated! 🦇",
        "Headlights on, world off. 🌑",
        "Late night revs! 🌙",
      ];
      return options[dayIndex];
    }
  }

  Future<void> _fetchUnreadNotificationCount() async {
    final data = await NotificationService().fetchNotifications(widget.token);
    final dashboardAnnouncement = await _pickDashboardAnnouncement(data);

    if (!mounted) return;
    setState(() {
      _notifications = data;
      _dashboardAnnouncement = dashboardAnnouncement;
      unreadNotificationCount = data.where((n) => n.unread).length;
    });
  }

  Future<NotificationItem?> _pickDashboardAnnouncement(
    List<NotificationItem> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final announcement = notifications
        .where((item) => item.type == "ANNOUNCEMENT_PUBLISHED")
        .cast<NotificationItem?>()
        .firstWhere((item) => item != null, orElse: () => null);

    if (announcement == null) return null;

    final seenKey = "seen_dashboard_announcement_${announcement.id}";
    final hasSeen = prefs.getBool(seenKey) ?? false;
    if (hasSeen) return null;

    await prefs.setBool(seenKey, true);
    return announcement;
  }

  Future<void> _syncUpcomingRideReminderNotifications() async {
    final upcomingRide = widget.userData?['upcomingRide'];
    if (upcomingRide is! Map<String, dynamic>) return;

    final startTimeRaw = upcomingRide['startTime']?.toString();
    if (startTimeRaw == null || startTimeRaw.isEmpty) return;

    final parsedStartTime = DateTime.tryParse(startTimeRaw);
    if (parsedStartTime == null) return;

    await NotificationService().notifyRideReminders(
      token: widget.token,
      rideTitle: upcomingRide['title']?.toString() ?? "Ride",
      rideId: upcomingRide['uuid']?.toString(),
      startTime: parsedStartTime.toLocal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final miles = _userData['weeklyMiles'] ?? 0;
    final avg = _userData['weeklyAvgMph'] ?? 0;
    final duration = _userData['weeklyDuration'] ?? 0;
    final todayRide = _mapValue('todayRide');
    final upcomingRide = _mapValue('upcomingRide');
    final recentRides = _mapListValue('recentRides');
    final achievements = _mapListValue('achievements');
    final todayPlanRide =
        todayRide ??
        (_isSameDay(_rideStartTime(upcomingRide), DateTime.now())
            ? upcomingRide
            : null);
    final dashboardRideStatus = _rideStatusForDashboard(
      todayRide: todayRide,
      todayPlanRide: todayPlanRide,
    );
    final showUpcomingRide =
        upcomingRide != null &&
        !_isSameDay(
          _rideStartTime(upcomingRide),
          _rideStartTime(todayPlanRide),
        ) &&
        !_isSameDay(_rideStartTime(upcomingRide), DateTime.now());
    final upcomingRideStatus = _normalizedRideStatus(upcomingRide);
    final cleanedTodaySubtitle = _cleanSubtitle(todayPlanRide);
    final upcomingDateLabel = _upcomingRideDateLabel(upcomingRide);
    final latestCompletedRide = recentRides.isNotEmpty
        ? recentRides.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userData != null
                              ? "${(_userData['firstName'] ?? '').toString().toCapitalized()} ${(_userData['lastName'] ?? '').toString().toCapitalized()}"
                                    .trim()
                              : "Guest",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    /// RIGHT SIDE ICONS
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.notifications_none,
                                  color: AppColors.textPrimary,
                                  size: 22,
                                ),
                                onPressed: () async {
                                  final result =
                                      await Navigator.push<
                                        List<NotificationItem>
                                      >(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => NotificationsScreen(
                                            onClose: () {},
                                            token: widget.token,
                                            initialNotifications:
                                                _notifications,
                                          ),
                                        ),
                                      );

                                  if (result != null && mounted) {
                                    setState(() {
                                      _notifications = result;
                                      unreadNotificationCount = result
                                          .where((n) => n.unread)
                                          .length;
                                    });
                                  }
                                },
                              ),
                            ),

                            /// 🔥 SHOW COUNT (only if > 0)
                            if (unreadNotificationCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadNotificationCount > 99
                                          ? "99+"
                                          : "$unreadNotificationCount",
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_dashboardAnnouncement != null) ...[
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x337D39EB), Color(0x22C6FF33)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: .35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dashboardAnnouncement!.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _dashboardAnnouncement!.desc,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
              if (_dashboardAnnouncement == null) const SizedBox(height: 25),

              /// TODAY'S PLAN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sectionHeading(todayRide),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (todayPlanRide == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          "No plans for today. Time to explore! 🏍️",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => _openRideConsoleFromDashboard(
                          todayPlanRide,
                          rideStatus: dashboardRideStatus,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: .1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.map,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todayPlanRide['title']?.toString() ??
                                          "Ride",
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cleanedTodaySubtitle,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (dashboardRideStatus == "ACTIVE")
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _openRideConsoleFromDashboard(
                                                todayPlanRide,
                                                rideStatus: dashboardRideStatus,
                                              ),
                                          child: const Text("Open Ride"),
                                        ),
                                      )
                                    else
                                      Text(
                                        "Tap to open partial start and ride controls",
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// UPCOMING RIDE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upcoming Ride",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!showUpcomingRide)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          "No upcoming rides yet.",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => _openRideGroup(
                          upcomingRide,
                          rideStatus: upcomingRideStatus,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: .12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.directions_bike,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      upcomingRide['title']?.toString() ??
                                          "Ride",
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      upcomingDateLabel,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          size: 13,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          upcomingRide['time']?.toString() ??
                                              "",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.people,
                                          size: 13,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${(upcomingRide['riders'] ?? 1) == 0 ? 1 : upcomingRide['riders']} joined",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        onPressed: () =>
                                            _openRideConsoleFromDashboard(
                                              upcomingRide,
                                              rideStatus: upcomingRideStatus,
                                            ),
                                        child: Text(
                                          _isStartedRideStatus(
                                                upcomingRideStatus,
                                              )
                                              ? "Open Ride"
                                              : "Start Ride",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textHint,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              /// RECENT RIDE
              if (latestCompletedRide != null) ...[
                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Last Ride",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.route, color: AppColors.primary),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                latestCompletedRide['title']?.toString() ??
                                    "Ride",
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              /// ACHIEVEMENT
              if (achievements.isNotEmpty) ...[
                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Latest Achievement",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                achievements.last['title']?.toString() ??
                                    "Achievement",
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              /// WEEK STATS (ONLY IF DATA EXISTS)
              if (!(miles == 0 && avg == 0 && duration == 0)) ...[
                const SizedBox(height: 25),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "This Week",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      if (miles != 0) ...[
                        Expanded(
                          child: StatCard(title: "Miles", value: "$miles"),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (avg != 0) ...[
                        Expanded(
                          child: StatCard(title: "Avg MPH", value: "$avg"),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (duration != 0)
                        Expanded(
                          child: StatCard(
                            title: "Duration",
                            value: "${duration}h",
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 15),

              const SizedBox(height: 25),

              /// WEATHER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _isLoadingWeather
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    // Map weather icon string to Flutter IconData
                                    _getIconData(_weatherData?['icon']),
                                    color: AppColors.textSecondary,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _weatherData?['description'] ??
                                              "Weather Unavailable",
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _cityName ?? "Location Unavailable",
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _weatherData != null
                                  ? "${_weatherData!['temperature']}°"
                                  : "--°",
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    if (iconName == null) return Icons.cloud;

    switch (iconName) {
      case 'cloud_off':
        return Icons.wb_sunny;
      case 'cloud':
        return Icons.cloud;
      case 'foggy':
        return Icons.foggy;
      case 'grain':
        return Icons.grain;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'water_drop':
        return Icons.water_drop;
      case 'tsunami':
        return Icons.waves; // Generic closest for rain shower
      case 'thunderstorm':
        return Icons.thunderstorm;
      default:
        return Icons.cloud;
    }
  }
}

/// REUSABLE STAT CARD
class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
