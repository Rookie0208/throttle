import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/features/rides/presentation/screens/ride_summary_screen.dart';

class StatsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StatsScreen({super.key, this.userData});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String activeTab = "analytics";
  late DateTime _heatmapMonth;
  Map<String, dynamic>? _userData;

  final badges = [
    {'name': 'Century Rider', 'desc': '100 miles in a day', 'earned': true},
    {'name': 'Speed Demon', 'desc': 'Hit 100+ mph', 'earned': true},
    {'name': 'Early Bird', 'desc': '5 rides before 7 AM', 'earned': true},
    {'name': 'Iron Streak', 'desc': '30-day streak', 'earned': false},
  ];

  List<Map<String, dynamic>> get rideHistory =>
      _userData != null && _userData!['recentRides'] is List
      ? List<Map<String, dynamic>>.from(_userData!['recentRides'])
      : const [];

  List<_RideInsight> get _rideInsights {
    final insights =
        rideHistory.map(_buildRideInsight).whereType<_RideInsight>().toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return insights;
  }

  int get totalRides {
    final total = int.tryParse((_userData?['totalRides'] ?? '').toString());
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
      _userData?['totalKm'] ??
          _userData?['totalDistanceKm'] ??
          _userData?['distanceKm'],
    );
    if (fromUserKm > 0) return fromUserKm;

    final fromMiles = _toDouble(_userData?['totalMiles']);
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
      (ride['date'] ?? ride['startTime'] ?? '').toString();

  String _rideTime(Map<String, dynamic> ride) =>
      (ride['time'] ?? ride['duration'] ?? '').toString();

  DateTime? _rideParsedDate(Map<String, dynamic> ride) {
    final raw =
        (ride['startTime'] ??
                ride['date'] ??
                ride['scheduledDate'] ??
                ride['startTime'] ??
                ride['rideStartedAt'] ??
                ride['createdAt'])
            ?.toString()
            .trim();
    if (raw == null || raw.isEmpty) return null;

    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;

    final normalizedRaw = _normalizeShortDate(raw);

    final formats = [
      DateFormat('MMM d, yyyy'),
      DateFormat('MMM d yyyy'),
      DateFormat('MMM d'),
      DateFormat('d MMM yyyy'),
      DateFormat('d MMM'),
      DateFormat('yyyy-MM-dd'),
    ];

    for (final format in formats) {
      try {
        final parsed = format.parseStrict(normalizedRaw);
        if (!normalizedRaw.contains(RegExp(r'\d{4}'))) {
          return DateTime(DateTime.now().year, parsed.month, parsed.day);
        }
        return parsed;
      } catch (_) {}
    }
    return null;
  }

  String _normalizeShortDate(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final match = RegExp(
      r'^([A-Za-z]{3,})\s+(\d{1,2})(.*)$',
    ).firstMatch(normalized);
    if (match == null) {
      return normalized;
    }

    final month = match.group(1)!;
    final day = match.group(2)!;
    final tail = match.group(3) ?? '';
    final canonicalMonth =
        "${month[0].toUpperCase()}${month.substring(1).toLowerCase()}";
    return "$canonicalMonth $day$tail";
  }

  double _parseDurationHours(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return 0;

    final hourMatch = RegExp(r'(\d+(?:\.\d+)?)\s*h').firstMatch(value);
    final minuteMatch = RegExp(r'(\d+(?:\.\d+)?)\s*m').firstMatch(value);
    final hours = hourMatch != null
        ? (double.tryParse(hourMatch.group(1)!) ?? 0)
        : 0;
    final minutes = minuteMatch != null
        ? (double.tryParse(minuteMatch.group(1)!) ?? 0)
        : 0;

    if (hours > 0 || minutes > 0) {
      return hours + (minutes / 60);
    }

    final numeric = double.tryParse(value);
    return numeric ?? 0;
  }

  double _rideSpeedKmh(Map<String, dynamic> ride) {
    final explicit = _toDouble(
      ride['avgSpeed'] ?? ride['averageSpeed'] ?? ride['speedKmh'],
    );
    if (explicit > 0) return explicit;

    final distanceKm = _rideDistanceKm(ride);
    final durationHours = _parseDurationHours(_rideTime(ride));
    if (distanceKm > 0 && durationHours > 0) {
      return distanceKm / durationHours;
    }
    return 0;
  }

  _RideInsight? _buildRideInsight(Map<String, dynamic> ride) {
    final date = _rideParsedDate(ride);
    if (date == null) return null;

    final distanceKm = _rideDistanceKm(ride);
    final speedKmh = _rideSpeedKmh(ride);
    if (distanceKm <= 0 && speedKmh <= 0) return null;

    return _RideInsight(
      title: _rideTitle(ride),
      date: date,
      distanceKm: distanceKm,
      speedKmh: speedKmh,
      durationLabel: _rideTime(ride),
      dateLabel: _rideDate(ride),
    );
  }

  double get _bestSpeedKmh => _rideInsights.fold<double>(
    0,
    (best, ride) => math.max(best, ride.speedKmh),
  );

  double get _averageSpeedKmh {
    final rides = _rideInsights.where((ride) => ride.speedKmh > 0).toList();
    if (rides.isEmpty) {
      return _toDouble(_userData?['weeklyAvgMph']) * 1.60934;
    }
    final total = rides.fold<double>(0, (sum, ride) => sum + ride.speedKmh);
    return total / rides.length;
  }

  String _formatSpeed(double value) {
    if (value <= 0) return "0 km/h";
    return "${value.toStringAsFixed(value >= 100 ? 0 : 1)} km/h";
  }

  String _formatChartValue(double value) {
    if (value <= 0) return "0";
    return value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  Map<DateTime, double> get _activityByDay {
    final activity = <DateTime, double>{};
    for (final ride in rideHistory) {
      final parsed = _rideParsedDate(ride);
      if (parsed == null) continue;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      final distance = math.max(_rideDistanceKm(ride), 1).toDouble();
      activity.update(
        day,
        (value) => value + distance,
        ifAbsent: () => distance,
      );
    }
    return activity;
  }

  List<_ChartPoint> get _distanceChartPoints {
    if (_rideInsights.isEmpty) return const [];
    var cumulativeDistance = 0.0;
    return List.generate(_rideInsights.length, (index) {
      final ride = _rideInsights[index];
      cumulativeDistance += ride.distanceKm;
      return _ChartPoint(
        x: index.toDouble(),
        y: cumulativeDistance,
        label: DateFormat('MMM d').format(ride.date),
        detail:
            "${ride.title} • ${_formatKm(ride.distanceKm)} ride • ${_formatKm(cumulativeDistance)} total",
      );
    });
  }

  List<_ChartPoint> get _speedChartPoints {
    if (_rideInsights.isEmpty) return const [];
    return List.generate(_rideInsights.length, (index) {
      final ride = _rideInsights[index];
      return _ChartPoint(
        x: index.toDouble(),
        y: ride.speedKmh,
        label: DateFormat('MMM d').format(ride.date),
        detail: "${ride.title} • ${_formatSpeed(ride.speedKmh)}",
      );
    }).where((point) => point.y > 0).toList();
  }

  String get _ridingStyleLabel {
    if (_rideInsights.isEmpty) {
      return "Style not ready";
    }

    if (totalDistanceKm >= 250 ||
        _rideInsights.any((ride) => ride.distanceKm >= 120)) {
      return "Endurance rider";
    }
    if (_bestSpeedKmh >= 85 || _averageSpeedKmh >= 65) {
      return "Fast cruiser";
    }
    if (_activityByDay.length >= 5) {
      return "Consistent explorer";
    }
    return "Balanced tourer";
  }

  String get _ridingStyleNote {
    if (_rideInsights.isEmpty) {
      return "Recent ride metrics will unlock speed, endurance, and consistency patterns.";
    }

    if (totalDistanceKm >= 250 ||
        _rideInsights.any((ride) => ride.distanceKm >= 120)) {
      return "Your recent rides lean long-distance. Endurance days are the clearest pattern in your history.";
    }
    if (_bestSpeedKmh >= 85 || _averageSpeedKmh >= 65) {
      return "Your pace trends high. Speed is the strongest signal across your recent rides.";
    }
    if (_activityByDay.length >= 5) {
      return "You ride regularly across the month, which points to a steady, repeatable riding rhythm.";
    }
    return "Your recent rides are balanced across distance and pace without one pattern dominating yet.";
  }

  Future<void> _openRideSummary(Map<String, dynamic> ride) async {
    final rideUuid = (ride["uuid"] ?? ride["id"])?.toString();
    final groupName = (ride["title"] ?? ride["name"] ?? "Ride").toString();
    final token = await AuthService.getToken();

    Map<String, dynamic>? session;
    if (rideUuid != null &&
        rideUuid.isNotEmpty &&
        token != null &&
        token.isNotEmpty) {
      try {
        session = await RideService.fetchRideSession(token, rideUuid);
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideSummaryScreen(
          groupName: groupName,
          ride: ride,
          session: session,
          token: token,
          rideUuid: rideUuid,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _heatmapMonth = DateTime(now.year, now.month);
    _userData = widget.userData != null
        ? Map<String, dynamic>.from(widget.userData!)
        : null;
    _refreshProfile();
  }

  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData && widget.userData != null) {
      _userData = Map<String, dynamic>.from(widget.userData!);
    }
  }

  Future<void> _refreshProfile() async {
    final freshUser = await UserService.getMe();
    if (!mounted || freshUser == null) return;
    setState(() {
      _userData = freshUser;
    });
  }

  DateTime get _currentMonth =>
      DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isViewingCurrentMonth =>
      _heatmapMonth.year == _currentMonth.year &&
      _heatmapMonth.month == _currentMonth.month;

  Map<DateTime, double> _activityForMonth(DateTime month) {
    final monthActivity = <DateTime, double>{};
    for (final entry in _activityByDay.entries) {
      final day = entry.key;
      if (day.year == month.year && day.month == month.month) {
        monthActivity[day] = entry.value;
      }
    }
    return monthActivity;
  }

  String _activitySummaryForMonth(DateTime month) {
    final monthActivity = _activityForMonth(month);
    final activeDays = monthActivity.values.where((value) => value > 0).length;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    return "$activeDays active day${activeDays == 1 ? '' : 's'} in ${DateFormat('MMMM yyyy').format(month)} • $daysInMonth-day view";
  }

  void _showPreviousMonth() {
    setState(() {
      _heatmapMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month - 1);
    });
  }

  void _showNextMonth() {
    if (_isViewingCurrentMonth) {
      return;
    }
    setState(() {
      _heatmapMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month + 1);
    });
  }

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
                      _buildTabButton("Ranking", "gamification", theme),
                    ],
                  ),
                ),

                if (activeTab == "analytics") ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildInsightHero(theme),
                  ),

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
                              "Avg Speed",
                              _formatSpeed(_averageSpeedKmh),
                              theme,
                            ),
                            const SizedBox(width: 12),
                            _statCard(
                              "Best Speed",
                              _formatSpeed(_bestSpeedKmh),
                              theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _sectionHeader("Speed Trend", theme),
                  _buildLineChartCard(
                    title: "Ride-by-ride average speed",
                    subtitle:
                        "Shows how fast the rider usually moves across recent rides.",
                    points: _speedChartPoints,
                    theme: theme,
                    lineColor: theme.primary,
                    metricLabel: "km/h",
                  ),

                  _sectionHeader("Distance Over Time", theme),
                  _buildLineChartCard(
                    title: "Distance covered per ride",
                    subtitle:
                        "Cumulative distance makes long-run weeks and steady volume easier to spot.",
                    points: _distanceChartPoints,
                    theme: theme,
                    lineColor: Colors.orangeAccent,
                    metricLabel: "km",
                  ),

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

  Widget _buildLineChartCard({
    required String title,
    required String subtitle,
    required List<_ChartPoint> points,
    required AppThemeConfig theme,
    required Color lineColor,
    required String metricLabel,
  }) {
    if (points.isEmpty) {
      return _insufficientDataCard(
        theme,
        title: title,
        message:
            "Needs at least 2 rides with distance and duration data to show a reliable trend.",
      );
    }

    final maxY = points.fold<double>(0, (max, point) => math.max(max, point.y));
    final interval = math.max(maxY / 4, 1).toDouble();

    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: maxY == 0 ? 10 : maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.textPrimary.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (value, meta) => Text(
                        _formatChartValue(value),
                        style: TextStyle(
                          color: theme.textPrimary.withValues(alpha: 0.45),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            points[index].label,
                            style: TextStyle(
                              color: theme.textPrimary.withValues(alpha: 0.45),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => theme.background,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final point = points[spot.x.round()];
                      return LineTooltipItem(
                        "${point.detail}\n${_formatChartValue(spot.y)} $metricLabel",
                        TextStyle(
                          color: theme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points
                        .map((point) => FlSpot(point.x, point.y))
                        .toList(),
                    isCurved: true,
                    barWidth: 3,
                    color: lineColor,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 3.5,
                            color: lineColor,
                            strokeWidth: 1.5,
                            strokeColor: theme.surface,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insufficientDataCard(
    AppThemeConfig theme, {
    required String title,
    required String message,
  }) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.55),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(AppThemeConfig theme) {
    final monthActivity = _activityForMonth(_heatmapMonth);
    final maxIntensity = monthActivity.values.fold<double>(
      0,
      (max, value) => math.max(max, value),
    );
    final firstDayOfMonth = DateTime(
      _heatmapMonth.year,
      _heatmapMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _heatmapMonth.year,
      _heatmapMonth.month,
    );
    final leadingEmptySlots = firstDayOfMonth.weekday % 7;
    final totalSlots = leadingEmptySlots + daysInMonth;
    final rowCount = (totalSlots / 7).ceil();
    final calendarDays = List<DateTime?>.generate(rowCount * 7, (index) {
      final dayNumber = index - leadingEmptySlots + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        return null;
      }
      return DateTime(_heatmapMonth.year, _heatmapMonth.month, dayNumber);
    });
    const weekLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Activity intensity by day",
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _activitySummaryForMonth(_heatmapMonth),
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: _showPreviousMonth,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: theme.textPrimary,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_heatmapMonth),
                    style: GoogleFonts.lexend(
                      color: theme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _isViewingCurrentMonth ? null : _showNextMonth,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: _isViewingCurrentMonth
                      ? theme.textPrimary.withValues(alpha: 0.24)
                      : theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 6.0;
              final tileSize = ((constraints.maxWidth - (gap * 6)) / 7).clamp(
                34.0,
                52.0,
              );

              return Column(
                children: [
                  Row(
                    children: List.generate(7, (index) {
                      return Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              weekLabels[index],
                              style: TextStyle(
                                color: theme.textPrimary.withValues(
                                  alpha: 0.45,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  ...List.generate(rowCount, (weekIndex) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: weekIndex == rowCount - 1 ? 0 : gap,
                      ),
                      child: Row(
                        children: List.generate(7, (dayIndex) {
                          final day = calendarDays[(weekIndex * 7) + dayIndex];
                          if (day == null) {
                            return Expanded(
                              child: Container(
                                height: tileSize,
                                margin: EdgeInsets.only(
                                  right: dayIndex == 6 ? 0 : gap,
                                ),
                              ),
                            );
                          }

                          final normalizedDay = DateTime(
                            day.year,
                            day.month,
                            day.day,
                          );
                          final intensity = monthActivity[normalizedDay] ?? 0;
                          final normalized = maxIntensity <= 0
                              ? 0
                              : (intensity / maxIntensity).clamp(0, 1);
                          final opacity = normalized == 0
                              ? 0.08
                              : 0.22 + (normalized * 0.70);

                          return Expanded(
                            child: Container(
                              height: tileSize,
                              margin: EdgeInsets.only(
                                right: dayIndex == 6 ? 0 : gap,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(10),
                                border: intensity > 0
                                    ? Border.all(
                                        color: theme.primary.withValues(
                                          alpha: 0.55,
                                        ),
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Tooltip(
                                message:
                                    "${DateFormat('EEE, MMM d').format(day)} • ${intensity <= 0 ? 'No ride' : _formatKm(intensity)}",
                                child: Text(
                                  "${day.day}",
                                  style: TextStyle(
                                    color: normalized > 0.42
                                        ? Colors.white
                                        : theme.textPrimary.withValues(
                                            alpha: 0.62,
                                          ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ],
              );
            },
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
                    color: theme.primary.withValues(alpha: 0.08 + (i * 0.22)),
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
    final speed = _rideSpeedKmh(ride);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openRideSummary(ride),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.textPrimary.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_bike,
                  color: theme.primary,
                  size: 20,
                ),
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
                    const SizedBox(height: 2),
                    Text(
                      _rideDate(ride),
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap for full summary",
                      style: TextStyle(
                        color: theme.primary.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                  if (speed > 0)
                    Text(
                      _formatSpeed(speed),
                      style: TextStyle(
                        color: theme.primary.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textPrimary.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightHero(AppThemeConfig theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Riding style",
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _ridingStyleLabel.toUpperCase(),
            style: GoogleFonts.bebasNeue(
              color: theme.primary,
              fontSize: 28,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _ridingStyleNote,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.68),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _RideInsight {
  final String title;
  final DateTime date;
  final double distanceKm;
  final double speedKmh;
  final String durationLabel;
  final String dateLabel;

  const _RideInsight({
    required this.title,
    required this.date,
    required this.distanceKm,
    required this.speedKmh,
    required this.durationLabel,
    required this.dateLabel,
  });
}

class _ChartPoint {
  final double x;
  final double y;
  final String label;
  final String detail;

  const _ChartPoint({
    required this.x,
    required this.y,
    required this.label,
    required this.detail,
  });
}
