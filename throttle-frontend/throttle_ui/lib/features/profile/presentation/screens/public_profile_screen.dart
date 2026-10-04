import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/features/profile/data/services/friend_service.dart';
import 'package:throttle_ui/features/profile/data/services/user_service.dart';
import 'package:throttle_ui/core/services/logger_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const PublicProfileScreen({super.key, required this.user});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  String _ctx(String action, [Map<String, Object?> fields = const {}]) {
    final suffix = fields.entries.map((e) => '${e.key}=${e.value}').join(' ');
    return suffix.isEmpty
        ? '[PUBLIC_PROFILE] action=$action'
        : '[PUBLIC_PROFILE] action=$action $suffix';
  }

  int mutualCount = 0;
  bool isLoadingMutual = true;
  bool isActionLoading = true;
  bool isLoadingProfile = false;
  String relationshipStatus = 'unknown';
  int? incomingRequestId;
  late Map<String, dynamic> _profile;

  @override
  void initState() {
    super.initState();
    _profile = Map<String, dynamic>.from(widget.user);
    _fetchProfile();
    _fetchMutualCount();
    _fetchRelationshipStatus();
  }

  String? get _targetUuid =>
      (_profile['uuid'] ?? widget.user['uuid']) as String?;

  Map<String, dynamic> get _displayUser => _profile;

  String get _visibilityMode =>
      (_displayUser['visibilityMode'] ?? 'public').toString().toLowerCase();

  bool get _isFriendView =>
      _visibilityMode == 'friend' || _visibilityMode == 'self';

  bool get _isSelfView => _visibilityMode == 'self';

  String get _displayName {
    final username = (_displayUser['username'] ?? '').toString().trim();
    final firstName = (_displayUser['firstName'] ?? '').toString().trim();
    final lastName = (_displayUser['lastName'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (username.isNotEmpty) return username;
    return 'Rider';
  }

  String get _profileImageUrl =>
      (_displayUser['profileImage'] ?? '').toString().trim();

  List<Map<String, dynamic>> get _recentRides {
    final rides = _displayUser['recentRides'];
    if (rides is! List) return const [];
    return rides.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  List<Map<String, dynamic>> get _achievements {
    final achievements = _displayUser['achievements'];
    if (achievements is! List) return const [];
    return achievements
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  List<Map<String, dynamic>> get _publicGroups {
    final groups = _displayUser['publicGroups'];
    if (groups is! List) return const [];
    return groups.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Future<void> _fetchProfile() async {
    final uuid = _targetUuid;
    if (uuid == null || uuid.isEmpty) {
      return;
    }
    setState(() => isLoadingProfile = true);
    final profile = await UserService.getProfileByUuid(uuid);
    if (mounted) {
      setState(() {
        if (profile != null) {
          _profile = {...profile, 'uuid': uuid};
        }
        isLoadingProfile = false;
      });
    }
  }

  void _fetchMutualCount() async {
    final uuid = _targetUuid;
    if (uuid == null) {
      setState(() => isLoadingMutual = false);
      return;
    }
    await Logger.info(_ctx('fetch_mutual_count', {'target': uuid}));
    final count = await FriendService.getMutualFriendsCount(uuid);
    if (mounted) {
      setState(() {
        mutualCount = count;
        isLoadingMutual = false;
      });
    }
  }

  Future<void> _fetchRelationshipStatus() async {
    final uuid = _targetUuid;
    if (uuid == null) {
      if (mounted) {
        setState(() {
          relationshipStatus = 'unknown';
          isActionLoading = false;
        });
      }
      return;
    }

    await Logger.info(_ctx('fetch_relationship', {'target': uuid}));
    final data = await FriendService.getRelationshipStatus(uuid);
    if (mounted) {
      setState(() {
        relationshipStatus = (data['status'] ?? 'unknown').toString();
        incomingRequestId = data['requestId'] is int
            ? data['requestId'] as int
            : null;
        isActionLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_targetUuid == null) return;
    await Logger.info(_ctx('tap_add_friend', {'target': _targetUuid}));
    setState(() => isActionLoading = true);
    final success = await FriendService.sendRequest(_targetUuid!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Friend request sent' : 'Unable to send friend request',
        ),
      ),
    );

    await _fetchRelationshipStatus();
  }

  Future<void> _acceptFriendRequest() async {
    if (incomingRequestId == null) return;
    await Logger.info(
      _ctx('tap_accept_request', {
        'target': _targetUuid,
        'requestId': incomingRequestId,
      }),
    );
    setState(() => isActionLoading = true);
    final success = await FriendService.acceptRequest(incomingRequestId!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Friend request accepted' : 'Unable to accept request',
        ),
      ),
    );

    if (success) await _fetchProfile();
    await _fetchRelationshipStatus();
  }

  Future<void> _unfriend() async {
    if (_targetUuid == null) return;
    await Logger.info(_ctx('tap_unfriend', {'target': _targetUuid}));
    setState(() => isActionLoading = true);
    final success = await FriendService.unfriend(_targetUuid!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Friend removed' : 'Unable to unfriend right now',
        ),
      ),
    );

    if (success) await _fetchProfile();
    await _fetchRelationshipStatus();
  }

  Widget _buildRelationshipButton() {
    final colorScheme = Theme.of(context).colorScheme;
    if (isActionLoading) {
      return SizedBox(
        height: 36,
        width: 36,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
    }

    switch (relationshipStatus) {
      case 'friends':
        return ElevatedButton(
          onPressed: _unfriend,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('Unfriend'),
        );
      case 'request_sent':
        return const ElevatedButton(
          onPressed: null,
          child: Text('Request Sent'),
        );
      case 'request_received':
        return ElevatedButton(
          onPressed: _acceptFriendRequest,
          child: const Text('Accept Request'),
        );
      case 'self':
        return const SizedBox.shrink();
      case 'none':
      default:
        return ElevatedButton(
          onPressed: _sendFriendRequest,
          child: const Text('Add Friend'),
        );
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _rideDistanceKm(Map<String, dynamic> ride) {
    final distanceKm = _toDouble(ride['distanceKm']);
    if (distanceKm > 0) return distanceKm;
    final miles = _toDouble(ride['miles']);
    return miles > 0 ? miles * 1.60934 : 0;
  }

  double _rideSpeedKmh(Map<String, dynamic> ride) {
    return _toDouble(
      ride['avgSpeed'] ?? ride['averageSpeed'] ?? ride['speedKmh'],
    );
  }

  int get _badgeCount {
    final explicit = _displayUser['badgeCount'];
    if (explicit is int) return explicit;
    return _achievements.length;
  }

  int get _bikeCount {
    final explicit = _displayUser['bikeCount'];
    if (explicit is int) return explicit;
    final bikes = _displayUser['bikes'];
    if (bikes is List) return bikes.length;
    return 0;
  }

  Map<DateTime, double> get _activityByDay {
    final activity = <DateTime, double>{};
    for (final ride in _recentRides) {
      final parsed = DateTime.tryParse((ride['startTime'] ?? '').toString());
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

  List<FlSpot> get _speedSpots {
    final spots = <FlSpot>[];
    for (var i = 0; i < _recentRides.length; i++) {
      final speed = _rideSpeedKmh(_recentRides[i]);
      if (speed > 0) {
        spots.add(FlSpot(i.toDouble(), speed));
      }
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = _displayUser;
    final String name = _displayName;
    final String riderId = (user["riderId"] ?? "").toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Rider Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroCard(colorScheme, textTheme, user, name, riderId),
          const SizedBox(height: 18),
          _buildPublicStatsRow(),
          const SizedBox(height: 18),
          if (!_isFriendView && !_isSelfView) _buildPublicLockCard(),
          if (_isFriendView) ...[
            _buildFriendJourneyCard(),
            const SizedBox(height: 18),
            _buildRecentRidesSection(),
            const SizedBox(height: 18),
            _buildGroupsSection(),
            const SizedBox(height: 18),
            _buildAchievementsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    ColorScheme colorScheme,
    TextTheme textTheme,
    Map<String, dynamic> user,
    String name,
    String riderId,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.primary,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : null,
                child: _profileImageUrl.isNotEmpty
                    ? null
                    : Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "R",
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (riderId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "@$riderId",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      (user["bio"] ?? "Motorcycle enthusiast").toString(),
                      style: textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    if (!isLoadingMutual && mutualCount > 0) ...[
                      const SizedBox(height: 10),
                      _metaPill(
                        Icons.diversity_3_outlined,
                        "$mutualCount mutual friends",
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildRelationshipButton(),
                  if (isLoadingProfile)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Loading profile...",
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicStatsRow() {
    final user = _displayUser;
    final totalKm = _toDouble(user["totalKm"]) > 0
        ? _toDouble(user["totalKm"])
        : _toDouble(user["totalMiles"]) * 1.60934;
    return Row(
      children: [
        _stat("Rides", "${user["totalRides"] ?? 0}"),
        const SizedBox(width: 8),
        _stat("Km", _formatKm(totalKm)),
        const SizedBox(width: 8),
        _stat("Badges", "$_badgeCount"),
        if (_isFriendView) ...[
          const SizedBox(width: 8),
          _stat("Bikes", "$_bikeCount"),
        ],
      ],
    );
  }

  Widget _buildPublicLockCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final message =
        (_displayUser['publicMessage'] ??
                'You are not a friend. Add friend to see their journey.')
            .toString();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Journey locked",
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendJourneyCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Journey snapshot",
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Friends can see a light version of riding activity. Full ride details stay hidden for future subscription-based access.",
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _buildHeatmapCard(),
          const SizedBox(height: 18),
          _buildSpeedTrendCard(),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final leading = monthStart.weekday % 7;
    final totalSlots = leading + daysInMonth;
    final rows = (totalSlots / 7).ceil();
    final maxIntensity = _activityByDay.values.fold<double>(
      0,
      (max, value) => math.max(max, value),
    );
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly ride heatmap",
            style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            "Days with ride activity are highlighted.",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 6.0;
              final tileSize = ((constraints.maxWidth - (gap * 6)) / 7).clamp(
                26.0,
                42.0,
              );
              return Column(
                children: [
                  Row(
                    children: labels
                        .map(
                          (label) => Expanded(
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(rows, (row) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: row == rows - 1 ? 0 : gap,
                      ),
                      child: Row(
                        children: List.generate(7, (col) {
                          final slot = row * 7 + col;
                          final dayNumber = slot - leading + 1;
                          if (dayNumber < 1 || dayNumber > daysInMonth) {
                            return Expanded(
                              child: Container(
                                height: tileSize,
                                margin: EdgeInsets.only(
                                  right: col == 6 ? 0 : gap,
                                ),
                              ),
                            );
                          }
                          final day = DateTime(now.year, now.month, dayNumber);
                          final intensity = _activityByDay[day] ?? 0;
                          final normalized = maxIntensity <= 0
                              ? 0.0
                              : (intensity / maxIntensity).clamp(0.0, 1.0);
                          final opacity = normalized == 0
                              ? 0.08
                              : 0.22 + (normalized * 0.68);
                          return Expanded(
                            child: Container(
                              height: tileSize,
                              margin: EdgeInsets.only(
                                right: col == 6 ? 0 : gap,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: opacity,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: normalized > 0.42
                                      ? Colors.white
                                      : null,
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
        ],
      ),
    );
  }

  Widget _buildSpeedTrendCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final spots = _speedSpots;
    if (spots.length < 2) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Not enough ride data yet to show a speed trend.",
          style: TextStyle(fontSize: 13),
        ),
      );
    }

    final maxY = spots.fold<double>(0, (max, spot) => math.max(max, spot.y));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Speed trend",
            style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            "A lightweight view of recent pace, not full ride analytics.",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_recentRides.length - 1).toDouble(),
                minY: 0,
                maxY: maxY == 0 ? 10 : maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    color: colorScheme.primary,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.12),
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

  Widget _buildRecentRidesSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return _sectionShell(
      title: "Recent rides",
      child: _recentRides.isEmpty
          ? const Text("No recent rides to show yet.")
          : Column(
              children: _recentRides.map((ride) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.22,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (ride['title'] ?? 'Ride').toString(),
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (ride['date'] ?? '').toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
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
                            style: GoogleFonts.bebasNeue(fontSize: 20),
                          ),
                          Text(
                            (ride['duration'] ?? '').toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                          if (_rideSpeedKmh(ride) > 0)
                            Text(
                              "${_rideSpeedKmh(ride).toStringAsFixed(0)} km/h avg",
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildGroupsSection() {
    return _sectionShell(
      title: "Public groups",
      child: _publicGroups.isEmpty
          ? const Text("No public groups visible.")
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _publicGroups.map((group) {
                final title = (group['title'] ?? group['name'] ?? 'Group')
                    .toString();
                final subtitle = (group['name'] ?? '').toString();
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
                      ),
                      if (subtitle.isNotEmpty && subtitle != title) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAchievementsSection() {
    return _sectionShell(
      title: "Achievements & badges",
      child: _achievements.isEmpty
          ? const Text("No earned badges visible yet.")
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _achievements.map((achievement) {
                return Container(
                  width: 170,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (achievement['title'] ?? 'Badge').toString(),
                        style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (achievement['description'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Theme.of(context).textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _sectionShell({required String title, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  String _formatKm(double value) {
    if (value <= 0) return "0 km";
    if (value >= 100) return "${value.toStringAsFixed(0)} km";
    return "${value.toStringAsFixed(1)} km";
  }

  Widget _stat(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
                  ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
