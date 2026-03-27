import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:throttle_ui/screens/notification_screen.dart';
import 'package:throttle_ui/services/notification_service.dart';
import 'package:throttle_ui/services/user_service.dart';
import 'package:throttle_ui/utils/constants.dart';
import '../utils/string_extensions.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/logger_service.dart';

class AppColors {
  static const primary = Color(0xfffe6603);
  static const background = Color(0xff0f1114);
  static const card = Color(0xff16181d);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const border = Colors.white12;
}

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String token;

  const DashboardScreen({super.key, this.userData, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _cityName;
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  int unreadNotificationCount = 0;
  String? _userUuid;
  StompClient? _notificationClient;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndWeather();
    _initializeNotifications();
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
    if (!mounted) return;

    setState(() {
      unreadNotificationCount = data.where((n) => n.unread).length;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                              ? "${(widget.userData!['firstName'] ?? '').toString().toCapitalized()} ${(widget.userData!['lastName'] ?? '').toString().toCapitalized()}"
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
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NotificationsScreen(
                                        onClose: () {
                                          Navigator.pop(context);
                                        },
                                        token: widget.token,
                                      ),
                                    ),
                                  );

                                  /// 🔥 OPTIONAL: refresh count after coming back
                                  _fetchUnreadNotificationCount();
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
                                        color: Colors.white,
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

              /// START RIDE BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.flash_on, color: Colors.white, size: 26),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Start Ride",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Begin tracking your ride",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// WEEK STATS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatCard(
                      title: "Miles",
                      value: widget.userData != null
                          ? "${widget.userData!['weeklyMiles'] ?? 0}"
                          : "0",
                    ),
                    StatCard(
                      title: "Avg MPH",
                      value: widget.userData != null
                          ? "${widget.userData!['weeklyAvgMph'] ?? 0}"
                          : "0",
                    ),
                    StatCard(
                      title: "Duration",
                      value: widget.userData != null
                          ? "${widget.userData!['weeklyDuration'] ?? 0}h"
                          : "0h",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// UPCOMING RIDE CARD
              if (widget.userData != null &&
                  widget.userData!['upcomingRide'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
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
                        Text(
                          widget.userData!['upcomingRide']['title']
                                  ?.toString() ??
                              "Upcoming Ride",
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userData!['upcomingRide']['subtitle']
                                  ?.toString() ??
                              "",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
