import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/features/rides/presentation/screens/live_ride_screen.dart';
import 'package:throttle_ui/features/rides/presentation/screens/ride_start_screen.dart';
import 'package:throttle_ui/features/rides/presentation/screens/ride_summary_screen.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

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

  TextStyle _eyebrowStyle(Color color) => GoogleFonts.lexend(
    color: color.withValues(alpha: 0.6),
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
  );

  TextStyle _sectionTitleStyle(Color color) => GoogleFonts.lexend(
    color: color,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.05,
  );

  TextStyle _cardTitleStyle(Color color) => GoogleFonts.lexend(
    color: color,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  TextStyle _bodyStyle(Color color) => GoogleFonts.plusJakartaSans(
    color: color.withValues(alpha: 0.7),
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  BoxDecoration _sectionDecoration(AppThemeConfig theme, {Color? color}) {
    return BoxDecoration(
      color: color ?? theme.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0x52B8C6DA)),
    );
  }

  BoxDecoration _cardDecoration(AppThemeConfig theme, {Color? color}) {
    return BoxDecoration(
      color: color ?? theme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: const Color(0x52B8C6DA).withValues(alpha: 0.75),
      ),
      boxShadow: [
        BoxShadow(
          color: theme.textPrimary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _sectionShell({
    required String eyebrow,
    required String title,
    String? action,
    required Widget child,
    required AppThemeConfig theme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _sectionDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: _eyebrowStyle(theme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(title, style: _sectionTitleStyle(theme.textPrimary)),
                    ],
                  ),
                ),
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    action,
                    style: GoogleFonts.lexend(
                      color: theme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String text, AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.tertiary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: theme.textPrimary.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      final status = _normalizedRideStatus(todayRide);
      if (status != "SCHEDULED") {
        return status;
      }
      final subtitle = todayRide["subtitle"]?.toString().toUpperCase() ?? "";
      if (subtitle.contains("IN PROGRESS")) {
        return "ACTIVE";
      }
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

  DateTime? _parseRideDate(dynamic value) {
    final raw = value?.toString().trim() ?? "";
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  bool _isCompletedRide(Map<String, dynamic>? ride) {
    final status = _normalizedRideStatus(ride);
    return status == "COMPLETED" || status == "ENDED";
  }

  DateTime? _rideCompletionTime(Map<String, dynamic>? ride) {
    return _parseRideDate(ride?["completedAt"]) ??
        _parseRideDate(ride?["rideCompletedAt"]) ??
        _parseRideDate(ride?["endTime"]) ??
        _parseRideDate(ride?["updatedAt"]) ??
        _parseRideDate(ride?["startTime"]) ??
        _parseRideDate(ride?["createdAt"]);
  }

  Map<String, dynamic>? _latestCompletedRide(List<Map<String, dynamic>> rides) {
    final completed = rides.where(_isCompletedRide).toList();
    if (completed.isEmpty) {
      return rides.isNotEmpty ? rides.first : null;
    }

    completed.sort((a, b) {
      final aTime = _rideCompletionTime(a);
      final bTime = _rideCompletionTime(b);
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return completed.first;
  }

  String _formatTimeOfDay(DateTime? dateTime) {
    if (dateTime == null) return "";
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? "PM" : "AM";
    return "$hour:$minutes $suffix";
  }

  String _recentRideSubtitle(Map<String, dynamic>? ride) {
    final completedAt = _rideCompletionTime(ride);
    final location = _rideLocationLabel(ride);
    final timeLabel = _formatTimeOfDay(completedAt);
    if (timeLabel.isNotEmpty) {
      return "$location • $timeLabel";
    }
    return location;
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

  Future<void> _openRideSummaryFromDashboard(Map<String, dynamic> ride) async {
    final rideUuid = (ride["uuid"] ?? ride["id"])?.toString();
    final title = (ride["title"] ?? "Ride").toString();

    if (rideUuid == null || rideUuid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open ride summary")),
      );
      return;
    }

    Map<String, dynamic>? session;
    try {
      session = await RideService.fetchRideSession(widget.token, rideUuid);
    } catch (error) {
      Logger.warn("Failed to fetch ride summary session for $rideUuid: $error");
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideSummaryScreen(
          groupName: title,
          session: session,
          ride: ride,
          token: widget.token,
          rideUuid: rideUuid,
        ),
      ),
    );
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
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        final borderSideColor = const Color(0x52B8C6DA);

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
        final latestCompletedRide = _latestCompletedRide(recentRides);

        return Scaffold(
          backgroundColor: theme.background,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.background,
                  theme.background.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.userData != null
                                    ? "${(_userData['firstName'] ?? '').toString().toCapitalized()} ${(_userData['lastName'] ?? '').toString().toCapitalized()}"
                                          .trim()
                                    : "Guest",
                                style: GoogleFonts.lexend(
                                  color: theme.textPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
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
                                      color: theme.surface.withValues(
                                        alpha: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.textPrimary.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.notifications_none,
                                        color: theme.textPrimary,
                                        size: 22,
                                      ),
                                      onPressed: () async {
                                        final result =
                                            await Navigator.push<
                                              List<NotificationItem>
                                            >(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    NotificationsScreen(
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
                                          color: theme.primary,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                            style: TextStyle(
                                              color: theme.surface,
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
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 20, 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffFAF9FF), Color(0xffEEF4FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderSideColor),
                            boxShadow: [
                              BoxShadow(
                                color: theme.textPrimary.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.campaign_rounded,
                                  color: theme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _dashboardAnnouncement!.title,
                                      style: GoogleFonts.lexend(
                                        color: theme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _dashboardAnnouncement!.desc,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: theme.textPrimary.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
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
                      const SizedBox(height: 6),
                    ],
                    if (_dashboardAnnouncement == null)
                      const SizedBox(height: 8),

                    /// TODAY'S PLAN
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                      child: _sectionShell(
                        eyebrow: "Live ride",
                        title: _sectionHeading(todayRide),
                        theme: theme,
                        child: todayPlanRide == null
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: _cardDecoration(
                                  theme,
                                  color: theme.surface,
                                ),
                                child: Text(
                                  "No plans for today. Time to explore! 🏍️",
                                  style: _bodyStyle(theme.textPrimary),
                                ),
                              )
                            : GestureDetector(
                                onTap: () => _openRideConsoleFromDashboard(
                                  todayPlanRide,
                                  rideStatus: dashboardRideStatus,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: _cardDecoration(theme),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.map_outlined,
                                          color: theme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              todayPlanRide['title']
                                                      ?.toString() ??
                                                  "Ride",
                                              style: _cardTitleStyle(
                                                theme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              cleanedTodaySubtitle,
                                              style: _bodyStyle(
                                                theme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            if (dashboardRideStatus == "ACTIVE")
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        theme.primary,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _openRideConsoleFromDashboard(
                                                        todayPlanRide,
                                                        rideStatus:
                                                            dashboardRideStatus,
                                                      ),
                                                  child: Text(
                                                    "Open Ride",
                                                    style: GoogleFonts.lexend(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              Text(
                                                "Tap to open partial start and ride controls",
                                                style: GoogleFonts.lexend(
                                                  color: theme.primary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),

                    /// UPCOMING RIDE
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                      child: _sectionShell(
                        eyebrow: "Next departure",
                        title: "Upcoming Ride",
                        theme: theme,
                        action: showUpcomingRide ? "View Route" : null,
                        child: !showUpcomingRide
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: _cardDecoration(theme),
                                child: Text(
                                  "No upcoming rides yet.",
                                  style: _bodyStyle(theme.textPrimary),
                                ),
                              )
                            : GestureDetector(
                                onTap: () => _openRideGroup(
                                  upcomingRide,
                                  rideStatus: upcomingRideStatus,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: _cardDecoration(theme),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.directions_bike_rounded,
                                          color: theme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              upcomingRide['title']
                                                      ?.toString() ??
                                                  "Ride",
                                              style: _cardTitleStyle(
                                                theme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              upcomingDateLabel,
                                              style: _bodyStyle(
                                                theme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _metaPill(
                                                  Icons.schedule_outlined,
                                                  upcomingRide['time']
                                                          ?.toString() ??
                                                      "",
                                                  theme,
                                                ),
                                                _metaPill(
                                                  Icons.people_outline,
                                                  "${(upcomingRide['riders'] ?? 1) == 0 ? 1 : upcomingRide['riders']} joined",
                                                  theme,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              _isStartedRideStatus(
                                                    upcomingRideStatus,
                                                  )
                                                  ? "Ride will open once active"
                                                  : "Ride scheduled for later",
                                              style: _bodyStyle(
                                                theme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Icon(
                                          Icons.chevron_right,
                                          color: theme.textPrimary.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),

                    /// RECENT RIDE
                    if (latestCompletedRide != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                        child: _sectionShell(
                          eyebrow: "Recently completed",
                          title: "Last Ride",
                          theme: theme,
                          child: Container(
                            width: double.infinity,
                            decoration: _cardDecoration(theme),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _openRideSummaryFromDashboard(
                                  latestCompletedRide,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.route_rounded,
                                          color: theme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              latestCompletedRide['title']
                                                      ?.toString() ??
                                                  "Ride",
                                              style: _cardTitleStyle(
                                                theme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _recentRideSubtitle(
                                                latestCompletedRide,
                                              ),
                                              style: _bodyStyle(
                                                theme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.chevron_right,
                                        color: theme.textPrimary.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    /// ACHIEVEMENT
                    if (achievements.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                        child: _sectionShell(
                          eyebrow: "Progress marker",
                          title: "Latest Achievement",
                          theme: theme,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: _cardDecoration(theme),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.tertiary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.emoji_events_rounded,
                                    color: theme.tertiary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    achievements.last['title']?.toString() ??
                                        "Achievement",
                                    style: _cardTitleStyle(theme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    /// WEEK STATS (ONLY IF DATA EXISTS)
                    if (!(miles == 0 && avg == 0 && duration == 0)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                        child: _sectionShell(
                          eyebrow: "At a glance",
                          title: "This Week",
                          theme: theme,
                          child: Row(
                            children: [
                              if (miles != 0) ...[
                                Expanded(
                                  child: StatCard(
                                    title: "Miles",
                                    value: "$miles",
                                    theme: theme,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (avg != 0) ...[
                                Expanded(
                                  child: StatCard(
                                    title: "Avg MPH",
                                    value: "$avg",
                                    theme: theme,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (duration != 0)
                                Expanded(
                                  child: StatCard(
                                    title: "Duration",
                                    value: "${duration}h",
                                    theme: theme,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    /// WEATHER
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _sectionShell(
                        eyebrow: "Road conditions",
                        title: "Weather",
                        theme: theme,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: _cardDecoration(
                            theme,
                            color: theme.surface.withValues(alpha: 0.9),
                          ),
                          child: _isLoadingWeather
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: theme.primary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: theme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            child: Icon(
                                              _getIconData(
                                                _weatherData?['icon'],
                                              ),
                                              color: theme.primary,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _weatherData?['description'] ??
                                                      "Weather Unavailable",
                                                  style: _cardTitleStyle(
                                                    theme.textPrimary,
                                                  ).copyWith(fontSize: 15),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _cityName ??
                                                      "Location Unavailable",
                                                  style: _bodyStyle(
                                                    theme.textPrimary,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                      style: GoogleFonts.lexend(
                                        color: theme.textPrimary,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
  final AppThemeConfig theme;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x52B8C6DA)),
        boxShadow: [
          BoxShadow(
            color: theme.textPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.lexend(
              color: theme.textPrimary.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
