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
        const SnackBar(content: Text("Please sign in again to update return ride")),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

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
        final checkpointsList = _stringList(
          _preRideInfo["checkpointList"] ?? _preRideInfo["checkpoints"],
        );
        final rules = _stringList(
          _preRideInfo["ruleList"] ?? _preRideInfo["rules"],
        );
        final broadcast = _value(data["latestBroadcastMessage"]);
        final sosMessage = _value(data["activeSosMessage"]);
        final participantsCount = _toInt(
          data["participantsCount"],
          people.length,
        );
        final inRideCount = _toInt(data["inRideCount"]);
        final atStartCount = _toInt(data["atStartCount"]);
        final enRouteCount = _toInt(data["enRouteCount"]);
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
                        padding: const EdgeInsets.all(18),
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
                                fontSize: 28,
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
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    "Total Duration",
                                    _formatDuration(duration),
                                    theme,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statCard(
                                    "Checkpoints",
                                    "$reachedCheckpoints/${checkpoints.length}",
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
                      _section("Ride Timeline", theme, [
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
                      ]),
                      const SizedBox(height: 18),
                      _section("Ride Setup", theme, [
                        _detailRow("Meeting Point", meetingPoint, theme),
                        _detailRow("Fuel Stops", fuelStops, theme),
                        _detailRow(
                          "En Route Riders",
                          enRouteCount.toString(),
                          theme,
                        ),
                        _detailRow(
                          "At Start Point",
                          atStartCount.toString(),
                          theme,
                        ),
                        _detailRow("In Ride", inRideCount.toString(), theme),
                        _detailRow("Notes", notes, theme),
                      ]),
                      if (checkpoints.isNotEmpty ||
                          checkpointsList.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _listSection(
                          "Checkpoints",
                          theme,
                          checkpoints.isNotEmpty
                              ? checkpoints.map((checkpoint) {
                                  final title = _value(checkpoint["title"]);
                                  final status = _value(
                                    checkpoint["checkpointStatus"],
                                  ).toUpperCase();
                                  final eta = _value(
                                    checkpoint["estimatedTime"],
                                  );
                                  return "$title${status != "-" ? " • $status" : ""}${eta != "-" ? " • $eta" : ""}";
                                }).toList()
                              : checkpointsList,
                        ),
                      ],
                      if (rules.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _listSection("Ride Rules", theme, rules),
                      ],
                      const SizedBox(height: 18),
                      _section("Ride Broadcast", theme, [
                        _detailRow("Captain Update", broadcast, theme),
                        _detailRow("Active SOS", sosMessage, theme),
                        _detailRow(
                          "SOS Raised By",
                          _value(data["activeSosRaisedByName"]),
                          theme,
                        ),
                        _detailRow(
                          "SOS Resolution",
                          _value(data["activeSosResolution"]),
                          theme,
                        ),
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

  Widget _section(String title, AppThemeConfig theme, List<Widget> children) {
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
          Text(
            title,
            style: GoogleFonts.bebasNeue(
              color: theme.textPrimary,
              fontSize: 22,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
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
