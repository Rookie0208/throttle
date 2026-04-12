import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String activeTab = "analytics";
  String timeRange = "weekly";

  // Dummy data
  final weeklyData = [
    {'day': 'Mon', 'miles': 32, 'speed': 48},
    {'day': 'Tue', 'miles': 0, 'speed': 0},
    {'day': 'Wed', 'miles': 45, 'speed': 52},
    {'day': 'Thu', 'miles': 18, 'speed': 38},
    {'day': 'Fri', 'miles': 65, 'speed': 56},
    {'day': 'Sat', 'miles': 88, 'speed': 62},
    {'day': 'Sun', 'miles': 0, 'speed': 0},
  ];

  final monthlyData = [
    {'week': 'W1', 'miles': 120},
    {'week': 'W2', 'miles': 185},
    {'week': 'W3', 'miles': 248},
    {'week': 'W4', 'miles': 310},
  ];

  final rideHistory = [
    {'date': 'Feb 13', 'name': 'Canyon Loop', 'miles': 68, 'time': '2h 15m'},
    {'date': 'Feb 11', 'name': 'Coastal Run', 'miles': 45, 'time': '1h 30m'},
    {'date': 'Feb 9', 'name': 'Mountain Pass', 'miles': 92, 'time': '3h 10m'},
  ];

  final badges = [
    {'name': 'Century Rider', 'desc': '100 miles in a day', 'earned': true},
    {'name': 'Speed Demon', 'desc': 'Hit 100+ mph', 'earned': true},
    {'name': 'Early Bird', 'desc': '5 rides before 7 AM', 'earned': true},
    {'name': 'Iron Streak', 'desc': '30-day streak', 'earned': false},
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            title: Text(
              "ANALYTICS & PROGRESS",
              style: GoogleFonts.bebasNeue(
                color: theme.textPrimary,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
            iconTheme: IconThemeData(color: theme.textPrimary),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab switcher
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildTabButton("Analytics", "analytics", theme),
                      const SizedBox(width: 8),
                      _buildTabButton("Gamification", "gamification", theme),
                    ],
                  ),
                ),

                if (activeTab == "analytics") ...[
                  // Grid summary (2x2)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _statCard("Total Distance", "248 mi", theme),
                            const SizedBox(width: 12),
                            _statCard("Avg Speed", "54 mph", theme),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statCard("Top Speed", "98 mph", theme),
                            const SizedBox(width: 12),
                            _statCard("Elevation Gain", "4,820 ft", theme),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _sectionHeader("Speed Trend", theme),
                  _chartPlaceholder("Speed Over Time (MPH)", theme),

                  _sectionHeader("Distance Over Time", theme),
                  _chartPlaceholder("Distance Covered (Miles)", theme),

                  _sectionHeader("Ride Heatmap", theme),
                  _buildHeatmap(theme),

                  _sectionHeader("Ride History", theme),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: rideHistory
                          .map((r) => _historyTile(r, theme))
                          .toList(),
                    ),
                  ),
                ],

                if (activeTab == "gamification") ...[
                  _sectionHeader("Badges & Challenges", theme),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _chartPlaceholder("Gamification Content", theme),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, String tab, AppThemeConfig theme) {
    final isSelected = activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.primary : theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: theme.textPrimary.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.bebasNeue(
                color: isSelected
                    ? Colors.white
                    : theme.textPrimary.withValues(alpha: 0.6),
                fontSize: 16,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, AppThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.bebasNeue(
          color: theme.textPrimary,
          fontSize: 18,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, AppThemeConfig theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.textPrimary.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.bebasNeue(
                color: theme.primary,
                fontSize: 24,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartPlaceholder(String label, AppThemeConfig theme) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.3),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmap(AppThemeConfig theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Column(
            children: List.generate(5, (weekIndex) {
              // 5 rows (weeks) for a wider monthly view
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (dayIndex) {
                  // 7 columns (days)
                  // Mock opacity based on activity
                  final double opacity = (weekIndex + dayIndex) % 5 == 0
                      ? 0.8
                      : (weekIndex + dayIndex) % 3 == 0
                      ? 0.35
                      : 0.1;
                  return Container(
                    width: 32, // Increased size for better visibility
                    height: 32,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Less ",
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
              ...List.generate(
                4,
                (i) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1 + (i * 0.25)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                " More",
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> ride, AppThemeConfig theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.directions_bike, color: theme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride['name'] as String,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ride['date'] as String,
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${ride['miles']} mi",
                style: GoogleFonts.bebasNeue(
                  color: theme.textPrimary,
                  fontSize: 18,
                ),
              ),
              Text(
                ride['time'] as String,
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
