import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/features/rides/presentation/screens/return_ride_screen.dart';

class RideSummaryScreen extends StatefulWidget {
  final String groupName;
  final Map<String, dynamic>? session;
  final Map<String, dynamic>? ride;
  final String? token;
  final String? rideUuid;

  const RideSummaryScreen({
    super.key,
    required this.groupName,
    this.session,
    this.ride,
    this.token,
    this.rideUuid,
  });

  @override
  State<RideSummaryScreen> createState() => _RideSummaryScreenState();
}

class _RideSummaryScreenState extends State<RideSummaryScreen> {
  Map<String, dynamic>? _session;
  bool _loading = false;
  bool _showVisualTimeline = true;
  int _activeBroadcastIndex = 0;

  String get _currentUserState =>
      (_session?["currentUserState"] ?? "").toString().toUpperCase();

  bool get _returnRideStarted => _currentUserState == "RETURN_RIDE_STARTED";

  bool get _returnRideCompleted => _currentUserState == "RETURN_RIDE_COMPLETED";

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    if (_session == null &&
        widget.rideUuid != null &&
        widget.rideUuid!.isNotEmpty) {
      _fetchSession();
    }
  }

  Future<void> _fetchSession() async {
    if (widget.rideUuid == null || widget.rideUuid!.isEmpty) return;

    final token = widget.token ?? await AuthService.getToken();
    if (token == null || token.isEmpty) return;

    setState(() => _loading = true);
    try {
      final session = await RideService.fetchRideSession(
        token,
        widget.rideUuid!,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst("Exception: ", "")),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<String, dynamic> get _ride => widget.ride ?? const {};
  Map<String, dynamic> get _data => {..._ride, ...?_session};

  Map<String, dynamic> get _preRideInfo {
    final sessionPreRide = _session?["preRideInfo"];
    if (sessionPreRide is Map<String, dynamic>) return sessionPreRide;

    final ridePreRide = _ride["preRideInfo"];
    if (ridePreRide is Map<String, dynamic>) return ridePreRide;

    return const {};
  }

  DateTime? _parseDate(dynamic value) {
    final raw = value?.toString().trim() ?? "";
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return "-";
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minutes = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? "PM" : "AM";
    return "$day/$month/$year • $hour:$minutes $suffix";
  }

  String _formatCompactDateTime(DateTime? value) {
    if (value == null) return "-";
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minutes = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? "PM" : "AM";
    return "${value.day}/${value.month} • $hour:$minutes $suffix";
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return "$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String _value(dynamic primary, [dynamic fallback]) {
    final candidate = (primary ?? fallback)?.toString().trim() ?? "";
    return candidate.isEmpty ? "-" : candidate;
  }

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? fallback;
  }

  double _toDouble(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? fallback;
  }

  String _formatDistance(double value) {
    if (value <= 0) return "-";
    if (value >= 100) return "${value.toStringAsFixed(0)} km";
    return "${value.toStringAsFixed(1)} km";
  }

  String _formatSpeed(double value) {
    if (value <= 0) return "-";
    return "${value.toStringAsFixed(value >= 100 ? 0 : 1)} km/h";
  }

  Duration _durationFromSeconds(dynamic value) {
    final seconds = _toInt(value);
    return Duration(seconds: math.max(seconds, 0));
  }

  Duration _durationFromMinutes(dynamic value) {
    final minutes = _toInt(value);
    return Duration(minutes: math.max(minutes, 0));
  }

  String _phaseDurationLabel(Duration duration) {
    if (duration == Duration.zero) return "0m";
    if (duration.inHours == 0) return "${duration.inMinutes}m";
    return "${duration.inHours}h ${duration.inMinutes % 60}m";
  }

  String _rideStyleLabel({
    required double distanceKm,
    required double avgSpeedKmh,
    required Duration totalDuration,
    required int checkpointsReached,
  }) {
    if (distanceKm >= 180 || totalDuration.inHours >= 5) {
      return "Endurance day";
    }
    if (avgSpeedKmh >= 75) {
      return "Fast cruise";
    }
    if (checkpointsReached >= 4) {
      return "Checkpoint hunter";
    }
    if (distanceKm > 0 || totalDuration > Duration.zero) {
      return "Balanced outing";
    }
    return "Session summary";
  }

  String _rideStyleDescription({
    required double distanceKm,
    required double avgSpeedKmh,
    required Duration totalDuration,
    required int checkpointsReached,
  }) {
    if (distanceKm >= 180 || totalDuration.inHours >= 5) {
      return "This trip leaned heavily toward endurance, with sustained saddle time and longer route commitment.";
    }
    if (avgSpeedKmh >= 75) {
      return "Pace was the standout signal here. This ride was more about speed and momentum than long-haul mileage.";
    }
    if (checkpointsReached >= 4) {
      return "The route was checkpoint-heavy, which usually means a more exploratory ride with frequent progress markers.";
    }
    if (distanceKm > 0 || totalDuration > Duration.zero) {
      return "Distance, time, and route progress stayed fairly balanced, so this reads as a steady all-round trip.";
    }
    return "Detailed trip metrics are limited for this session, but the layout still groups the ride into a readable summary.";
  }

  Future<void> _handleBackToHome() async {
    final rideUuid = widget.rideUuid;
    if (rideUuid == null || rideUuid.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final token = widget.token ?? await AuthService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please sign in again to update return ride"),
        ),
      );
      return;
    }

    if (_returnRideCompleted) {
      if (!mounted) return;
      Navigator.pop(context, _session);
      return;
    }

    setState(() => _loading = true);
    try {
      final wasReturnRideStarted = _returnRideStarted;
      final session = wasReturnRideStarted
          ? await RideService.fetchRideSession(token, rideUuid)
          : await RideService.startReturnRide(token, rideUuid);

      if (!mounted) return;
      setState(() {
        _session = session;
      });

      final message = wasReturnRideStarted
          ? "Resuming return ride"
          : "Return ride started";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReturnRideScreen(
            groupName: widget.groupName,
            token: token,
            rideUuid: rideUuid,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst("Exception: ", "")),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final raw = value?.toString().trim() ?? "";
    if (raw.isEmpty) return const [];
    return raw
        .split(",")
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  double? _coordinate(dynamic value) {
    final parsed = _toDouble(value, double.nan);
    if (parsed.isNaN || parsed == 0) return null;
    return parsed;
  }

  DateTime? _checkpointTime(Map<String, dynamic> checkpoint) {
    return _parseDate(
      checkpoint["reachedAt"] ??
          checkpoint["actualTime"] ??
          checkpoint["estimatedTime"] ??
          checkpoint["updatedAt"],
    );
  }

  List<_TimelineStop> _buildTimelineStops(Map<String, dynamic> data) {
    final stops = <_TimelineStop>[];

    void addStop({
      required String id,
      required String title,
      required String kind,
      Map<String, dynamic>? location,
      DateTime? time,
      String? subtitle,
      String? status,
    }) {
      final latitude = _coordinate(location?["latitude"] ?? location?["lat"]);
      final longitude = _coordinate(
        location?["longitude"] ?? location?["lng"] ?? location?["lon"],
      );
      stops.add(
        _TimelineStop(
          id: id,
          title: title,
          kind: kind,
          latitude: latitude,
          longitude: longitude,
          time: time,
          subtitle: subtitle,
          status: status,
        ),
      );
    }

    addStop(
      id: "start",
      title: _value(data["meetingPoint"], _preRideInfo["meetingPoint"]),
      kind: "start",
      location:
          _mapValue(data["meetingPointLocation"]) ??
          _mapValue(_preRideInfo["meetingPointLocation"]) ??
          _mapValue(_preRideInfo["startLocation"]) ??
          _mapValue(data["startLocation"]),
      time:
          _parseDate(data["rideStartedAt"]) ??
          _parseDate(data["scheduledStartTime"]) ??
          _parseDate(_ride["startTime"]),
      subtitle: "Meetup start",
      status: _value(data["rideStatus"], data["status"]).toUpperCase(),
    );

    final sessionCheckpoints = _mapList(data["checkpoints"]);
    if (sessionCheckpoints.isNotEmpty) {
      for (final checkpoint in sessionCheckpoints) {
        addStop(
          id: "checkpoint-${checkpoint["sequence"] ?? stops.length}",
          title: _value(checkpoint["title"], "Checkpoint"),
          kind: "checkpoint",
          location: checkpoint,
          time: _checkpointTime(checkpoint),
          subtitle: _value(checkpoint["locationType"], "Checkpoint"),
          status: _value(checkpoint["checkpointStatus"]).toUpperCase(),
        );
      }
    } else {
      final checkpointLocations = _mapList(_preRideInfo["checkpointLocations"]);
      for (var i = 0; i < checkpointLocations.length; i++) {
        final checkpoint = checkpointLocations[i];
        addStop(
          id: "planned-checkpoint-$i",
          title: _value(
            checkpoint["title"] ?? checkpoint["name"],
            "Checkpoint ${i + 1}",
          ),
          kind: "checkpoint",
          location: checkpoint,
          subtitle: "Planned checkpoint",
          status: "PLANNED",
        );
      }
    }

    addStop(
      id: "end",
      title: _value(
        _mapValue(_preRideInfo["endLocation"])?["name"],
        _mapValue(data["endLocation"])?["name"] ?? "Ride end",
      ),
      kind: "end",
      location:
          _mapValue(data["endLocation"]) ??
          _mapValue(_preRideInfo["endLocation"]),
      time:
          _parseDate(data["rideCompletedAt"]) ??
          _parseDate(data["completedAt"]) ??
          _parseDate(data["endTime"]),
      subtitle: "Ride finish",
      status: _value(data["rideStatus"], data["status"]).toUpperCase(),
    );

    return stops.where((stop) => stop.title != "-").toList();
  }

  List<_BroadcastCardData> _buildBroadcastCards(Map<String, dynamic> data) {
    final cards = <_BroadcastCardData>[];
    final broadcasts = _mapList(data["broadcasts"]);

    for (final broadcast in broadcasts) {
      final message = _value(broadcast["message"]);
      if (message == "-") continue;
      cards.add(
        _BroadcastCardData(
          title: "Captain broadcast",
          message: message,
          timestamp: _parseDate(broadcast["createdAt"]),
          accent: Colors.orangeAccent,
          icon: Icons.campaign_outlined,
        ),
      );
    }

    final latestBroadcast = _value(data["latestBroadcastMessage"]);
    if (latestBroadcast != "-" &&
        !cards.any((card) => card.message == latestBroadcast)) {
      cards.insert(
        0,
        _BroadcastCardData(
          title: "Latest update",
          message: latestBroadcast,
          timestamp: _parseDate(data["latestBroadcastAt"]),
          accent: Colors.orangeAccent,
          icon: Icons.campaign_outlined,
        ),
      );
    }

    final sosMessage = _value(data["activeSosMessage"]);
    if (sosMessage != "-") {
      cards.insert(
        0,
        _BroadcastCardData(
          title: "Active SOS",
          message: sosMessage,
          timestamp: _parseDate(data["activeSosAt"]),
          accent: Colors.redAccent,
          icon: Icons.sos_outlined,
          footer:
              "Raised by ${_value(data["activeSosRaisedByName"])} • ${_value(data["activeSosResolution"])}",
        ),
      );
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        final data = _data;
        final checkpoints = _mapList(data["checkpoints"]);
        final participants = _mapList(data["participants"]);
        final members = _mapList(_ride["members"]);
        final people = participants.isNotEmpty ? participants : members;
        final startedAt =
            _parseDate(data["rideStartedAt"]) ??
            _parseDate(data["scheduledStartTime"]) ??
            _parseDate(data["startTime"]);
        final completedAt =
            _parseDate(data["rideCompletedAt"]) ??
            _parseDate(data["completedAt"]) ??
            _parseDate(data["endTime"]) ??
            (_loading ? null : _parseDate(data["updatedAt"]));
        final duration = startedAt != null && completedAt != null
            ? completedAt.difference(startedAt)
            : Duration.zero;
        final reachedCheckpoints = checkpoints
            .where(
              (checkpoint) =>
                  (checkpoint["checkpointStatus"] ?? "")
                      .toString()
                      .toUpperCase() ==
                  "REACHED",
            )
            .length;
        final rideStatus = _value(
          data["rideStatus"],
          data["status"],
        ).toUpperCase();
        final meetingPoint = _value(
          data["meetingPoint"],
          _preRideInfo["meetingPoint"] ?? _ride["meetingPoint"],
        );
        final fuelStops = _value(_preRideInfo["fuelStops"], data["fuelStops"]);
        final notes = _value(_preRideInfo["notes"], data["notes"]);
        final rules = _stringList(
          _preRideInfo["ruleList"] ?? _preRideInfo["rules"],
        );
        final timelineStops = _buildTimelineStops(data);
        final broadcastCards = _buildBroadcastCards(data);
        if (_activeBroadcastIndex >= broadcastCards.length &&
            broadcastCards.isNotEmpty) {
          _activeBroadcastIndex = 0;
        }
        final participantsCount = _toInt(
          data["participantsCount"],
          people.length,
        );
        final inRideCount = _toInt(data["inRideCount"]);
        final atStartCount = _toInt(data["atStartCount"]);
        final enRouteCount = _toInt(data["enRouteCount"]);
        final returnRideStartedCount = _toInt(data["returnRideStartedCount"]);
        final returnRideCompletedCount = _toInt(
          data["returnRideCompletedCount"],
        );
        final distanceKm = _toDouble(
          data["currentUserDistanceKm"] ??
              data["distanceKm"] ??
              _ride["distanceKm"] ??
              _ride["km"] ??
              _ride["kilometers"],
        );
        final avgSpeedKmh = _toDouble(
          data["currentUserAverageSpeedKmh"] ??
              data["avgSpeed"] ??
              data["averageSpeed"] ??
              _ride["avgSpeed"] ??
              _ride["averageSpeed"],
        );
        final durationMinutes = _toInt(
          data["currentUserDurationMinutes"] ?? data["durationMinutes"],
        );
        final metricDuration = durationMinutes > 0
            ? _durationFromMinutes(durationMinutes)
            : duration;
        final timeToMeeting = _durationFromSeconds(
          data["currentUserTimeToMeetingSeconds"],
        );
        final groupRideDuration = _durationFromSeconds(
          data["currentUserGroupRideDurationSeconds"],
        );
        final returnRideDuration = _durationFromSeconds(
          data["currentUserReturnRideDurationSeconds"],
        );
        final phaseDurations = <_SummaryPhase>[
          _SummaryPhase("To meetup", timeToMeeting, theme.tertiary),
          _SummaryPhase("Main ride", groupRideDuration, theme.primary),
          _SummaryPhase("Return", returnRideDuration, theme.secondary),
        ].where((phase) => phase.duration > Duration.zero).toList();
        final rideStyleLabel = _rideStyleLabel(
          distanceKm: distanceKm,
          avgSpeedKmh: avgSpeedKmh,
          totalDuration: metricDuration,
          checkpointsReached: reachedCheckpoints,
        );
        final rideStyleDescription = _rideStyleDescription(
          distanceKm: distanceKm,
          avgSpeedKmh: avgSpeedKmh,
          totalDuration: metricDuration,
          checkpointsReached: reachedCheckpoints,
        );
        final showBackToHomeButton = !_returnRideCompleted;
        final backToHomeLabel = _returnRideStarted
            ? "Resume Return Ride"
            : "Back to Home";

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            title: Text(
              "Ride Summary",
              style: GoogleFonts.bebasNeue(color: theme.textPrimary),
            ),
            actions: [
              if (widget.rideUuid != null)
                IconButton(
                  onPressed: _loading ? null : _fetchSession,
                  icon: Icon(Icons.refresh, color: theme.textPrimary),
                ),
            ],
          ),
          body: _loading && data.isEmpty
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                rideStatus.isEmpty ? "COMPLETED" : rideStatus,
                                style: GoogleFonts.lexend(
                                  color: theme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.groupName,
                              style: GoogleFonts.bebasNeue(
                                fontSize: 32,
                                color: theme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _value(data["description"], _ride["description"]),
                              style: TextStyle(
                                color: theme.textPrimary.withValues(
                                  alpha: 0.68,
                                ),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.background,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rideStyleLabel.toUpperCase(),
                                    style: GoogleFonts.bebasNeue(
                                      color: theme.primary,
                                      fontSize: 24,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rideStyleDescription,
                                    style: TextStyle(
                                      color: theme.textPrimary.withValues(
                                        alpha: 0.7,
                                      ),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    "Ride Time",
                                    _formatDuration(metricDuration),
                                    theme,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statCard(
                                    "Distance",
                                    _formatDistance(distanceKm),
                                    theme,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    "Avg Speed",
                                    _formatSpeed(avgSpeedKmh),
                                    theme,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statCard(
                                    "Checkpoints",
                                    checkpoints.isEmpty
                                        ? "$reachedCheckpoints"
                                        : "$reachedCheckpoints/${checkpoints.length}",
                                    theme,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    "Riders",
                                    "$participantsCount joined",
                                    theme,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statCard(
                                    "Meetup",
                                    meetingPoint,
                                    theme,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _section("Trip Dashboard", theme, [
                        _buildTripMetricGrid(
                          theme,
                          participantsCount: participantsCount,
                          inRideCount: inRideCount,
                          atStartCount: atStartCount,
                          enRouteCount: enRouteCount,
                          returnRideStartedCount: returnRideStartedCount,
                          returnRideCompletedCount: returnRideCompletedCount,
                        ),
                        if (checkpoints.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildCheckpointProgress(
                            theme,
                            reachedCheckpoints: reachedCheckpoints,
                            totalCheckpoints: checkpoints.length,
                          ),
                        ],
                        if (phaseDurations.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildPhaseChart(theme, phaseDurations),
                        ],
                        const SizedBox(height: 18),
                        _buildParticipantStateChart(
                          theme,
                          enRouteCount: enRouteCount,
                          atStartCount: atStartCount,
                          inRideCount: inRideCount,
                          returnRideStartedCount: returnRideStartedCount,
                          returnRideCompletedCount: returnRideCompletedCount,
                        ),
                      ]),
                      const SizedBox(height: 18),
                      _section(
                        "Ride Timeline",
                        theme,
                        [
                          if (_showVisualTimeline)
                            _buildVisualTimeline(
                              theme,
                              stops: timelineStops,
                              startedAt: startedAt,
                              completedAt: completedAt,
                            )
                          else
                            Column(
                              children: [
                                _detailRow(
                                  "Started",
                                  _formatDateTime(startedAt),
                                  theme,
                                ),
                                _detailRow(
                                  "Completed",
                                  _formatDateTime(completedAt),
                                  theme,
                                ),
                                _detailRow(
                                  "Scheduled",
                                  _formatDateTime(
                                    _parseDate(data["scheduledStartTime"]) ??
                                        _parseDate(_ride["startTime"]),
                                  ),
                                  theme,
                                ),
                                if (timelineStops.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ...timelineStops.map(
                                    (stop) =>
                                        _buildTimelineTextRow(theme, stop),
                                  ),
                                ],
                              ],
                            ),
                        ],
                        headerAction: _timelineHeaderToggle(theme),
                      ),
                      const SizedBox(height: 18),
                      _section("Ride Setup", theme, [
                        _buildSetupGrid(
                          theme,
                          setupItems: [
                            _SetupItem(
                              icon: Icons.place_outlined,
                              label: "Meeting point",
                              value: meetingPoint,
                            ),
                            _SetupItem(
                              icon: Icons.local_gas_station_outlined,
                              label: "Fuel stops",
                              value: fuelStops,
                            ),
                            _SetupItem(
                              icon: Icons.rule_folder_outlined,
                              label: "Ride rules",
                              value: rules.isEmpty
                                  ? "-"
                                  : "${rules.length} saved",
                            ),
                            _SetupItem(
                              icon: Icons.note_alt_outlined,
                              label: "Notes",
                              value: notes,
                            ),
                          ],
                        ),
                      ]),
                      if (rules.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _listSection("Ride Rules", theme, rules),
                      ],
                      const SizedBox(height: 18),
                      _section("Ride Broadcast", theme, [
                        _buildBroadcastStack(theme, broadcastCards),
                      ]),
                      const SizedBox(height: 18),
                      _peopleSection(theme, people),
                      const SizedBox(height: 18),
                      if (showBackToHomeButton)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleBackToHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(backToHomeLabel),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _timelineAccent(AppThemeConfig theme, _TimelineStop stop) {
    final status = (stop.status ?? "").toUpperCase();
    if (stop.kind == "start" || status == "STARTED") return theme.secondary;
    if (stop.kind == "end" || status == "COMPLETED") return Colors.green;
    if (status == "REACHED") return Colors.orangeAccent;
    if (status == "UPCOMING" || status == "PLANNED") return theme.primary;
    return theme.primary;
  }

  IconData _timelineIcon(_TimelineStop stop) {
    final status = (stop.status ?? "").toUpperCase();
    if (stop.kind == "start" || status == "STARTED") return Icons.flag_circle;
    if (stop.kind == "end" || status == "COMPLETED") {
      return Icons.verified_rounded;
    }
    if (status == "REACHED") return Icons.location_on;
    return Icons.trip_origin;
  }

  String _timelineTooltip(_TimelineStop stop) {
    final timeLabel = _formatDateTime(stop.time);
    final status = _value(stop.status);
    final location = stop.latitude != null && stop.longitude != null
        ? "${stop.latitude!.toStringAsFixed(4)}, ${stop.longitude!.toStringAsFixed(4)}"
        : "Location unavailable";
    return "${stop.title}\n$status\n$timeLabel\n$location";
  }

  Widget _section(
    String title,
    AppThemeConfig theme,
    List<Widget> children, {
    Widget? headerAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.bebasNeue(
                    color: theme.textPrimary,
                    fontSize: 22,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              ...?headerAction == null ? null : [headerAction],
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _timelineHeaderToggle(AppThemeConfig theme) {
    return IconButton(
      tooltip: _showVisualTimeline
          ? "Switch to text timeline"
          : "Switch to visual timeline",
      onPressed: () {
        setState(() => _showVisualTimeline = !_showVisualTimeline);
      },
      icon: Icon(
        _showVisualTimeline ? Icons.view_list_rounded : Icons.route_rounded,
        color: theme.textPrimary,
      ),
      style: IconButton.styleFrom(
        backgroundColor: theme.background,
        foregroundColor: theme.textPrimary,
      ),
    );
  }

  Widget _buildTripMetricGrid(
    AppThemeConfig theme, {
    required int participantsCount,
    required int inRideCount,
    required int atStartCount,
    required int enRouteCount,
    required int returnRideStartedCount,
    required int returnRideCompletedCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard("Riders", "$participantsCount joined", theme),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard("In motion", "$inRideCount riding", theme),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard("At meetup", "$atStartCount ready", theme),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                "Returning",
                "$returnRideStartedCount back",
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard("En route", "$enRouteCount inbound", theme),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                "Return done",
                "$returnRideCompletedCount complete",
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckpointProgress(
    AppThemeConfig theme, {
    required int reachedCheckpoints,
    required int totalCheckpoints,
  }) {
    final progress = totalCheckpoints == 0
        ? 0.0
        : (reachedCheckpoints / totalCheckpoints).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Route progress",
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "$reachedCheckpoints of $totalCheckpoints checkpoints marked reached",
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.surface,
              color: theme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseChart(AppThemeConfig theme, List<_SummaryPhase> phases) {
    final totalMinutes = phases.fold<int>(
      0,
      (sum, phase) => sum + phase.duration.inMinutes,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Trip flow",
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "How your ride time was split across meetup, main ride, and return.",
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: phases.map((phase) {
                  final value = phase.duration.inMinutes.toDouble();
                  return PieChartSectionData(
                    value: value,
                    color: phase.color,
                    radius: 50,
                    title: totalMinutes == 0
                        ? "0%"
                        : "${((value / totalMinutes) * 100).round()}%",
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...phases.map(
            (phase) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: phase.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phase.label,
                      style: TextStyle(color: theme.textPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    _phaseDurationLabel(phase.duration),
                    style: GoogleFonts.lexend(
                      color: theme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Widget _buildParticipantStateChart(
    AppThemeConfig theme, {
    required int enRouteCount,
    required int atStartCount,
    required int inRideCount,
    required int returnRideStartedCount,
    required int returnRideCompletedCount,
  }) {
    final bars = <_StateBar>[
      _StateBar("En route", enRouteCount, theme.tertiary),
      _StateBar("At start", atStartCount, theme.secondary),
      _StateBar("In ride", inRideCount, theme.primary),
      _StateBar("Return", returnRideStartedCount, Colors.orangeAccent),
      _StateBar("Done", returnRideCompletedCount, Colors.green),
    ];
    final maxValue = bars.fold<int>(0, (max, bar) => math.max(max, bar.value));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rider distribution",
            style: GoogleFonts.lexend(
              color: theme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "A quick view of where the group was across the ride states.",
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                maxY: (maxValue == 0 ? 1 : maxValue + 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: theme.surface, strokeWidth: 1),
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
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
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
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= bars.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            bars[index].label,
                            style: TextStyle(
                              color: theme.textPrimary.withValues(alpha: 0.55),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(bars.length, (index) {
                  final bar = bars[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: bar.value.toDouble(),
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        color: bar.color,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, AppThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textPrimary.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualTimeline(
    AppThemeConfig theme, {
    required List<_TimelineStop> stops,
    required DateTime? startedAt,
    required DateTime? completedAt,
  }) {
    if (stops.isEmpty) {
      return _detailRow(
        "Timeline",
        "No route stops available for this ride.",
        theme,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 230,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.background, theme.surface],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final points = List<_RoutePlotPoint>.generate(stops.length, (
                index,
              ) {
                final x = stops.length == 1
                    ? constraints.maxWidth / 2
                    : (constraints.maxWidth - 28) *
                              (index / (stops.length - 1)) +
                          14;
                final yAnchors = [
                  constraints.maxHeight * 0.25,
                  constraints.maxHeight * 0.58,
                  constraints.maxHeight * 0.38,
                ];
                final y = yAnchors[index % yAnchors.length];
                return _RoutePlotPoint(x, y);
              });

              return Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _RoutePainter(
                      points: points,
                      color: theme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  ...List.generate(stops.length, (index) {
                    final stop = stops[index];
                    final point = points[index];
                    final icon = _timelineIcon(stop);
                    final markerColor = _timelineAccent(theme, stop);
                    final labelWidth = 84.0;
                    final markerLeft = ((point.x - 24).clamp(
                      0.0,
                      math.max(constraints.maxWidth - 48, 0),
                    )).toDouble();
                    final labelLeft = ((point.x - (labelWidth / 2)).clamp(
                      0.0,
                      math.max(constraints.maxWidth - labelWidth, 0),
                    )).toDouble();

                    return Positioned(
                      left: markerLeft,
                      top: point.y - 26,
                      child: Column(
                        children: [
                          Tooltip(
                            message: _timelineTooltip(stop),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: markerColor.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: markerColor.withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: markerColor.withValues(alpha: 0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: markerColor, size: 24),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Transform.translate(
                            offset: Offset(labelLeft - markerLeft, 0),
                            child: SizedBox(
                              width: labelWidth,
                              child: Column(
                                children: [
                                  Text(
                                    stop.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lexend(
                                      color: theme.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: markerColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _formatCompactDateTime(stop.time),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: markerColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _miniTimelineStat(
                  theme,
                  label: "Started",
                  value: _formatCompactDateTime(startedAt),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniTimelineStat(
                  theme,
                  label: "Completed",
                  value: _formatCompactDateTime(completedAt),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...stops.map((stop) => _buildTimelineStopCard(theme, stop)),
      ],
    );
  }

  Widget _miniTimelineStat(
    AppThemeConfig theme, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textPrimary.withValues(alpha: 0.55),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lexend(
            color: theme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStopCard(AppThemeConfig theme, _TimelineStop stop) {
    final accent = _timelineAccent(theme, stop);
    final coords = stop.latitude != null && stop.longitude != null
        ? "${stop.latitude!.toStringAsFixed(4)}, ${stop.longitude!.toStringAsFixed(4)}"
        : "Location data unavailable";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_timelineIcon(stop), color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.title,
                  style: GoogleFonts.lexend(
                    color: theme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (stop.status != null &&
                        stop.status != "-" &&
                        stop.status!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stop.status!,
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (stop.subtitle != null &&
                        stop.subtitle != "-" &&
                        stop.subtitle!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stop.subtitle!,
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.72),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  coords,
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.62),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatCompactDateTime(stop.time),
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.62),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTextRow(AppThemeConfig theme, _TimelineStop stop) {
    final accent = _timelineAccent(theme, stop);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_timelineIcon(stop), color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.title,
                  style: GoogleFonts.lexend(
                    color: theme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (stop.status != null &&
                        stop.status != "-" &&
                        stop.status!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stop.status!,
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (stop.subtitle != null &&
                        stop.subtitle != "-" &&
                        stop.subtitle!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stop.subtitle!,
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.72),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(stop.time),
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupGrid(
    AppThemeConfig theme, {
    required List<_SetupItem> setupItems,
  }) {
    final visibleItems = setupItems.where((item) => item.value != "-").toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: visibleItems.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: theme.primary, size: 20),
                    const SizedBox(height: 10),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: theme.textPrimary.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.value,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                        color: theme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBroadcastStack(
    AppThemeConfig theme,
    List<_BroadcastCardData> cards,
  ) {
    if (cards.isEmpty) {
      return Text(
        "No ride broadcasts were saved for this session.",
        style: TextStyle(color: theme.textPrimary.withValues(alpha: 0.65)),
      );
    }

    final activeCard = cards[_activeBroadcastIndex];

    return Column(
      children: [
        SizedBox(
          height: 196,
          child: Stack(
            children: [
              Positioned(
                left: 18,
                right: 18,
                top: 28,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 9,
                right: 9,
                top: 14,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) {
                  final slide =
                      Tween<Offset>(
                        begin: const Offset(0, 0.18),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      );
                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Container(
                  key: ValueKey("broadcast-$_activeBroadcastIndex"),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: activeCard.accent.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            activeCard.icon,
                            color: activeCard.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activeCard.title,
                              style: GoogleFonts.lexend(
                                color: theme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _formatCompactDateTime(activeCard.timestamp),
                            style: TextStyle(
                              color: theme.textPrimary.withValues(alpha: 0.55),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Text(
                          activeCard.message,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                      if (activeCard.footer != null &&
                          activeCard.footer!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          activeCard.footer!,
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              "${_activeBroadcastIndex + 1} / ${cards.length}",
              style: TextStyle(
                color: theme.textPrimary.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: cards.length <= 1
                  ? null
                  : () {
                      setState(() {
                        _activeBroadcastIndex =
                            (_activeBroadcastIndex - 1 + cards.length) %
                            cards.length;
                      });
                    },
              icon: Icon(Icons.chevron_left_rounded, color: theme.textPrimary),
            ),
            IconButton(
              onPressed: cards.length <= 1
                  ? null
                  : () {
                      setState(() {
                        _activeBroadcastIndex =
                            (_activeBroadcastIndex + 1) % cards.length;
                      });
                    },
              icon: Icon(Icons.chevron_right_rounded, color: theme.textPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _listSection(String title, AppThemeConfig theme, List<String> items) {
    return _section(
      title,
      theme,
      items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: theme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _peopleSection(
    AppThemeConfig theme,
    List<Map<String, dynamic>> people,
  ) {
    return _section(
      "Participants",
      theme,
      people.isEmpty
          ? [
              Text(
                "No participant details available.",
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.65),
                ),
              ),
            ]
          : people.map((person) {
              final name = _value(
                person["name"],
                "${person["firstName"] ?? ""} ${person["lastName"] ?? ""}"
                    .trim(),
              );
              final role = _value(person["role"]);
              final state = _value(person["rideState"], person["state"]);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primary.withValues(alpha: 0.12),
                      foregroundColor: theme.primary,
                      child: Text(
                        name == "-" ? "R" : name.characters.first.toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.lexend(
                              color: theme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              role,
                              state,
                            ].where((value) => value != "-").join(" • "),
                            style: TextStyle(
                              color: theme.textPrimary.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

class _SummaryPhase {
  final String label;
  final Duration duration;
  final Color color;

  const _SummaryPhase(this.label, this.duration, this.color);
}

class _StateBar {
  final String label;
  final int value;
  final Color color;

  const _StateBar(this.label, this.value, this.color);
}

class _TimelineStop {
  final String id;
  final String title;
  final String kind;
  final double? latitude;
  final double? longitude;
  final DateTime? time;
  final String? subtitle;
  final String? status;

  const _TimelineStop({
    required this.id,
    required this.title,
    required this.kind,
    required this.latitude,
    required this.longitude,
    required this.time,
    this.subtitle,
    this.status,
  });
}

class _SetupItem {
  final IconData icon;
  final String label;
  final String value;

  const _SetupItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _BroadcastCardData {
  final String title;
  final String message;
  final DateTime? timestamp;
  final Color accent;
  final IconData icon;
  final String? footer;

  const _BroadcastCardData({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.accent,
    required this.icon,
    this.footer,
  });
}

class _RoutePlotPoint {
  final double x;
  final double y;

  const _RoutePlotPoint(this.x, this.y);
}

class _RoutePainter extends CustomPainter {
  final List<_RoutePlotPoint> points;
  final Color color;

  const _RoutePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.x, points.first.y);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.x + current.x) / 2;
      path.cubicTo(
        controlX,
        previous.y,
        controlX,
        current.y,
        current.x,
        current.y,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
