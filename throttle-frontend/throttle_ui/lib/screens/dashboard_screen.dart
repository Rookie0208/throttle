import 'package:flutter/material.dart';
import 'package:throttle_ui/models/notification_model.dart';
import 'package:throttle_ui/screens/notification_screen.dart';
import 'package:throttle_ui/services/notification_service.dart';
import '../utils/string_extensions.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/logger_service.dart';
import 'package:throttle_ui/utils/app_colors.dart';

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
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    print("userData : "+widget.userData.toString());
    _fetchLocationAndWeather();
    _fetchUnreadNotificationCount();
    _syncUpcomingRideReminderNotifications();
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
    _notifications = data;
    unreadNotificationCount =
        data.where((n) => n.unread).length;
  });
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
    final miles = widget.userData?['weeklyMiles'] ?? 0;
    final avg = widget.userData?['weeklyAvgMph'] ?? 0;
    final duration = widget.userData?['weeklyDuration'] ?? 0;
    final rawSubtitle =
    widget.userData!['upcomingRide']['subtitle'] ?? "";

/// 🔥 Remove "10 Riders •"
final cleanedSubtitle = rawSubtitle.contains("•")
    ? rawSubtitle.split("•").skip(1).join("•").trim()
    : rawSubtitle;

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
              final result = await Navigator.push<List<NotificationItem>>(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                    onClose: () {},
                    token: widget.token,
                    initialNotifications: _notifications,
                  ),
                ),
              );

              if (result != null && mounted) {
                setState(() {
                  _notifications = result;
                  unreadNotificationCount =
                      result.where((n) => n.unread).length;
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
)
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
                            Icon(Icons.flash_on, color: AppColors.white, size: 26),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Start Ride",
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  "Begin tracking your ride",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

const SizedBox(height: 25),
              /// TODAY'S PLAN
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Today's Plan",
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),

      if (widget.userData?['todayRide'] == null)
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
        Container(
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
                  color: AppColors.primary.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map, color: AppColors.primary),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userData!['todayRide']['title'] ?? "Ride",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
  cleanedSubtitle, // 👉 now shows: "MAR 27 • 17:46"
  style: const TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
  ),
),
                  ],
                ),
              )
            ],
          ),
        ),
    ],
  ),
),

/// RECENT RIDE
if ((widget.userData?['recentRides'] ?? []).isNotEmpty) ...[
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
                  widget.userData!['recentRides'].last['title'] ?? "Ride",
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
if ((widget.userData?['achievements'] ?? []).isNotEmpty) ...[
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
                  widget.userData!['achievements'].last['title'] ??
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
          Expanded(child: StatCard(title: "Miles", value: "$miles")),
          const SizedBox(width: 10),
        ],
        if (avg != 0) ...[
          Expanded(child: StatCard(title: "Avg MPH", value: "$avg")),
          const SizedBox(width: 10),
        ],
        if (duration != 0)
          Expanded(child: StatCard(title: "Duration", value: "${duration}h")),
      ],
    ),
  ),
],
              const SizedBox(height: 15),

           /// UPCOMING RIDE CARD
if (widget.userData?['upcomingRide'] != null) ...[
  const SizedBox(height: 25),

  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: GestureDetector(
      onTap: () {
        // 👉 Navigate to ride group
      },
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
            /// ICON
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_bike, color: AppColors.primary),
            ),

            const SizedBox(width: 14),

            /// CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔥 TITLE (BIGGER NOW)
                  Text(
                    widget.userData!['upcomingRide']['title'] ?? "Ride",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// SUBTITLE
                  Text(
  cleanedSubtitle, // 👉 now shows: "MAR 27 • 17:46"
  style: const TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
  ),
),

                  const SizedBox(height: 10),

                  /// 🔥 INFO ROW (FIXED)
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        widget.userData!['upcomingRide']['time'] ?? "",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Icon(Icons.people, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),

                      /// ✅ FIX: ensure minimum 1 rider (captain)
                      Text(
                        "${(widget.userData!['upcomingRide']['riders'] ?? 1) == 0 ? 1 : widget.userData!['upcomingRide']['riders']} joined",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// ARROW
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    ),
  ),
],

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
                          child: CircularProgressIndicator(color: AppColors.primary),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _weatherData?['description'] ?? "Weather Unavailable",
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
                              _weatherData != null ? "${_weatherData!['temperature']}°" : "--°",
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
      case 'cloud_off': return Icons.wb_sunny;
      case 'cloud': return Icons.cloud;
      case 'foggy': return Icons.foggy;
      case 'grain': return Icons.grain;
      case 'ac_unit': return Icons.ac_unit;
      case 'water_drop': return Icons.water_drop;
      case 'tsunami': return Icons.waves; // Generic closest for rain shower
      case 'thunderstorm': return Icons.thunderstorm;
      default: return Icons.cloud;
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
