import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';

class StatsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StatsScreen({super.key, this.userData});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String activeTab = "analytics";

  final badges = [
    {'name': 'Century Rider', 'desc': '100 miles in a day', 'earned': true},
    {'name': 'Speed Demon', 'desc': 'Hit 100+ mph', 'earned': true},
    {'name': 'Early Bird', 'desc': '5 rides before 7 AM', 'earned': true},
    {'name': 'Iron Streak', 'desc': '30-day streak', 'earned': false},
  ];

  List<Map<String, dynamic>> get rideHistory =>
      widget.userData != null && widget.userData!['recentRides'] is List
      ? List<Map<String, dynamic>>.from(widget.userData!['recentRides'])
      : const [];

  int get totalRides {
    final total = int.tryParse(
      (widget.userData?['totalRides'] ?? '').toString(),
    );
    return total != null && total > 0 ? total : rideHistory.length;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final raw = value?.toString().trim() ?? "";
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  double _rideDistanceKm(Map<String, dynamic> ride) {
    final distanceKm = _toDouble(
      ride['distanceKm'] ?? ride['km'] ?? ride['kilometers'],
    );
    if (distanceKm > 0) return distanceKm;

    final distanceMiles = _toDouble(
      ride['miles'] ?? ride['distanceMiles'] ?? ride['distance'],
    );
    if (distanceMiles > 0) return distanceMiles * 1.60934;

    return 0;
  }

  double get totalDistanceKm {
    final fromHistory = rideHistory.fold<double>(
      0,
      (sum, ride) => sum + _rideDistanceKm(ride),
    );
    if (fromHistory > 0) return fromHistory;

    final fromUserKm = _toDouble(
      widget.userData?['totalKm'] ??
          widget.userData?['totalDistanceKm'] ??
          widget.userData?['distanceKm'],
    );
    if (fromUserKm > 0) return fromUserKm;

    final fromMiles = _toDouble(widget.userData?['totalMiles']);
    if (fromMiles > 0) return fromMiles * 1.60934;

    return 0;
  }

  String _formatKm(double value) {
    if (value == 0) return "0 km";
    if (value >= 100) return "${value.round()} km";
    return "${value.toStringAsFixed(1)} km";
  }

  String _rideTitle(Map<String, dynamic> ride) =>
      (ride['name'] ?? ride['title'] ?? 'Ride').toString();

  String _rideDate(Map<String, dynamic> ride) =>
      (ride['date'] ?? '').toString();

  String _rideTime(Map<String, dynamic> ride) =>
      (ride['time'] ?? ride['duration'] ?? '').toString();

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
                            _statCard(
                              "Total Distance",
                              _formatKm(totalDistanceKm),
                              theme,
                            ),
                            const SizedBox(width: 12),
                            _statCard("Total Rides", "$totalRides", theme),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statCard(
                              "Badges Earned",
                              "${badges.where((badge) => badge['earned'] == true).length}",
                              theme,
                            ),
                            const SizedBox(width: 12),
                            _statCard(
                              "Recent Rides",
                              "${rideHistory.length}",
                              theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _sectionHeader("Speed Trend", theme),
                  _chartPlaceholder("Speed analytics coming soon", theme),

                  _sectionHeader("Distance Over Time", theme),
                  _chartPlaceholder("Distance covered (KM)", theme),

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
                  _rideTitle(ride),
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _rideDate(ride),
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
                _formatKm(_rideDistanceKm(ride)),
                style: GoogleFonts.bebasNeue(
                  color: theme.textPrimary,
                  fontSize: 18,
                ),
              ),
              Text(
                _rideTime(ride),
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
