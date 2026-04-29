import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/services/location_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_refresh_notifier.dart';
import 'package:throttle_ui/features/rides/data/services/ride_realtime_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';

import 'live_ride_screen.dart';

class RideStartScreen extends StatefulWidget {
  final String groupName;
  final String rideDate;
  final String rideTime;
  final String location;
  final int memberCount;
  final String token;
  final String rideUuid;

  const RideStartScreen({
    super.key,
    required this.groupName,
    required this.rideDate,
    required this.rideTime,
    required this.location,
    required this.memberCount,
    required this.token,
    required this.rideUuid,
  });

  @override
  State<RideStartScreen> createState() => _RideStartScreenState();
}

class _RideStartScreenState extends State<RideStartScreen> {
  final RideRealtimeService _rideRealtimeService = RideRealtimeService();

  bool _loading = false;
  bool _fetching = false;
  bool _isDragging = false;
  bool _navigatingToLiveRide = false;
  double _dragPosition = 0;
  Map<String, dynamic>? _session;
  Timer? _clockTimer;
  Timer? _locationSyncTimer;
  Timer? _topToastTimer;
  LatLng? _currentMapLocation;
  bool _showTopToast = false;
  String? _topToastMessage;

  String get _title =>
      (_session?["title"] ?? widget.groupName).toString().trim().isEmpty
      ? "Ride"
      : (_session?["title"] ?? widget.groupName).toString();

  String get _rideStatus =>
      (_session?["rideStatus"] ?? "SCHEDULED").toString().toUpperCase();

  String get _currentUserState =>
      (_session?["currentUserState"] ?? "JOINED").toString().toUpperCase();

  bool get _canManageRide =>
      (_session?["currentUserCaptain"] == true) ||
      {
        "CAPTAIN",
        "ADMIN",
        "CO_CAPTAIN",
      }.contains((_session?["currentUserRole"] ?? "").toString().toUpperCase());

  int get _enRouteCount =>
      _toInt(_session?["enRouteCount"]) ??
      (_currentUserState == "EN_ROUTE" ? 1 : 0);

  int get _atStartCount =>
      _toInt(_session?["atStartCount"]) ??
      (_currentUserState == "AT_START_POINT" ? 1 : 0);

  int get _inRideCount =>
      _toInt(_session?["inRideCount"]) ??
      (_currentUserState == "IN_RIDE" ? 1 : 0);

  int get _participantsCount =>
      _toInt(_session?["participantsCount"]) ?? widget.memberCount;

  String get _meetingPoint {
    final value = (_session?["meetingPoint"] ?? widget.location)
        .toString()
        .trim();
    return value.isEmpty ? "Start point" : value;
  }

  _RideStartAction get _primaryAction {
    if (_rideStatus == "ACTIVE" || _currentUserState == "IN_RIDE") {
      return _RideStartAction.openLiveRide;
    }
    if (_rideStatus == "COMPLETED") {
      return _RideStartAction.completed;
    }
    if (_rideStatus == "CANCELLED") {
      return _RideStartAction.cancelled;
    }
    if (_currentUserState == "JOINED") {
      return _RideStartAction.startToMeeting;
    }
    if (_currentUserState == "EN_ROUTE") {
      return _RideStartAction.markArrived;
    }
    if (_currentUserState == "AT_START_POINT" && _canManageRide) {
      return _RideStartAction.beginJourney;
    }
    if (_currentUserState == "AT_START_POINT") {
      return _RideStartAction.waitForCaptain;
    }
    return _RideStartAction.refresh;
  }

  String get _primaryActionLabel {
    switch (_primaryAction) {
      case _RideStartAction.openLiveRide:
        return "OPEN LIVE RIDE";
      case _RideStartAction.completed:
        return "RIDE COMPLETED";
      case _RideStartAction.cancelled:
        return "RIDE CANCELLED";
      case _RideStartAction.startToMeeting:
        return "START RIDE";
      case _RideStartAction.markArrived:
        return "MARK ARRIVED";
      case _RideStartAction.beginJourney:
        return "BEGIN JOURNEY";
      case _RideStartAction.waitForCaptain:
        return "WAIT FOR CAPTAIN";
      case _RideStartAction.refresh:
        return "REFRESH";
    }
  }

  bool get _canSlideAction =>
      !_loading &&
      !_fetching &&
      _primaryAction != _RideStartAction.waitForCaptain &&
      _primaryAction != _RideStartAction.completed &&
      _primaryAction != _RideStartAction.cancelled;

  bool get _isRideCompleted => _rideStatus == "COMPLETED";
  bool get _isRideCancelled => _rideStatus == "CANCELLED";
  bool get _isRideClosed => _isRideCompleted || _isRideCancelled;

  bool get _hasRideStarted =>
      !_isRideClosed &&
      (_rideStatus == "ACTIVE" ||
          _currentUserState == "IN_RIDE" ||
          _session?["rideStartedAt"] != null);

  bool get _isOngoingToMeeting =>
      !_isRideClosed &&
      (_currentUserState == "EN_ROUTE" ||
          _currentUserState == "AT_START_POINT");

  bool get _showRideManagementAction => _canManageRide && !_isRideClosed;

  String get _rideManagementTitle =>
      _hasRideStarted ? "End Ride" : "Cancel Ride";

  String get _rideManagementDescription => _hasRideStarted
      ? "Are you sure you want to end this ride?"
      : "Are you sure you want to cancel this ride before it starts?";

  String get _rideManagementConfirmLabel =>
      _hasRideStarted ? "End Ride" : "Cancel Ride";

  DateTime? get _currentUserRideStartedAt => DateTime.tryParse(
    (_session?["currentUserRideStartedAt"] ?? "").toString(),
  );

  DateTime? get _currentUserArrivedAtStartAt => DateTime.tryParse(
    (_session?["currentUserArrivedAtStartAt"] ?? "").toString(),
  );

  int? get _currentUserTimeToMeetingSeconds =>
      _toInt(_session?["currentUserTimeToMeetingSeconds"]);

  Map<String, dynamic>? get _meetingPointLocation {
    final raw = _session?["meetingPointLocation"];
    if (raw is! Map) return null;
    final latitude = _toDouble(raw["latitude"]);
    final longitude = _toDouble(raw["longitude"]);
    if (latitude == null || longitude == null) return null;
    return {
      "name": (raw["name"] ?? _meetingPoint).toString(),
      "latitude": latitude,
      "longitude": longitude,
    };
  }

  LatLng? get _sessionCurrentUserLocation {
    final participants = _session?["participants"];
    if (participants is! List) return null;
    final currentUserUuid = (_session?["currentUserUuid"] ?? "").toString();
    for (final item in participants) {
      if (item is! Map) continue;
      if ((item["userUuid"] ?? "").toString() != currentUserUuid) continue;
      final latitude = _toDouble(item["lastLatitude"]);
      final longitude = _toDouble(item["lastLongitude"]);
      if (latitude != null && longitude != null) {
        return LatLng(latitude, longitude);
      }
    }
    return null;
  }

  LatLng? get _mapCurrentLocation =>
      _currentMapLocation ?? _sessionCurrentUserLocation;

  String get _phaseTitle {
    switch (_currentUserState) {
      case "EN_ROUTE":
        return "On the way to the meeting point";
      case "AT_START_POINT":
        return "Arrived at the meeting point";
      default:
        return "Get ready for the ride";
    }
  }

  @override
  void initState() {
    super.initState();
    _connectRealtime();
    _loadSession();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_currentUserRideStartedAt != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _locationSyncTimer?.cancel();
    _topToastTimer?.cancel();
    _rideRealtimeService.disconnect();
    super.dispose();
  }

  void _connectRealtime() {
    _rideRealtimeService.connect(
      token: widget.token,
      rideUuid: widget.rideUuid,
      onRideUpdated: () {
        if (!mounted) return;
        _loadSession();
      },
    );
  }

  Future<void> _loadSession() async {
    setState(() => _fetching = true);
    try {
      final previousState = _currentUserState;
      final session = await RideService.fetchRideSession(
        widget.token,
        widget.rideUuid,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
      _handleTopToast(previousState, _currentUserState);
      _ensureEnRouteLocationSync();
      _maybeOpenLiveRide(session);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _fetching = false);
      }
    }
  }

  void _maybeOpenLiveRide([Map<String, dynamic>? session]) {
    final rideStatus = (session?["rideStatus"] ?? _session?["rideStatus"] ?? "")
        .toString()
        .toUpperCase();
    final currentUserState =
        (session?["currentUserState"] ?? _session?["currentUserState"] ?? "")
            .toString()
            .toUpperCase();

    if (_navigatingToLiveRide) {
      return;
    }

    if (rideStatus == "ACTIVE" || currentUserState == "IN_RIDE") {
      _navigatingToLiveRide = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LiveRideScreen(
            groupName: _title,
            onEndRide: () => Navigator.pop(context),
            token: widget.token,
            rideUuid: widget.rideUuid,
          ),
        ),
      );
    }
  }

  void _ensureEnRouteLocationSync() {
    if (!_isOngoingToMeeting) {
      _locationSyncTimer?.cancel();
      _locationSyncTimer = null;
      return;
    }

    if (_locationSyncTimer != null) {
      return;
    }

    unawaited(_captureAndSyncLocation());
    _locationSyncTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_captureAndSyncLocation()),
    );
  }

  Future<void> _captureAndSyncLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position == null || !mounted) {
      return;
    }

    setState(() {
      _currentMapLocation = LatLng(position.latitude, position.longitude);
    });

    try {
      final session = await RideService.updateRideLocation(
        widget.token,
        widget.rideUuid,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
    } catch (_) {
      // Best-effort sync. The local position still drives the route view.
    }
  }

  Future<void> _completeRide() async {
    if (!_canManageRide) {
      _showSnack("Only captain/admin can end this ride");
      return;
    }

    setState(() => _loading = true);
    try {
      await RideService.completeRide(widget.token, widget.rideUuid);
      RideRefreshNotifier.notify();
      await _loadSession();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _cancelRide() async {
    if (!_canManageRide) {
      _showSnack("Only captain/admin can cancel this ride");
      return;
    }

    setState(() => _loading = true);
    try {
      await RideService.cancelRide(widget.token, widget.rideUuid);
      RideRefreshNotifier.notify();
      await _loadSession();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _performPrimaryAction() async {
    if (!_canSlideAction) {
      if (_primaryAction == _RideStartAction.waitForCaptain) {
        _showSnack("Waiting for the captain to start the ride");
      }
      return;
    }

    if (_primaryAction == _RideStartAction.openLiveRide) {
      _maybeOpenLiveRide();
      return;
    }

    setState(() => _loading = true);
    try {
      Map<String, dynamic>? session;

      switch (_primaryAction) {
        case _RideStartAction.startToMeeting:
          session = await RideService.partialStartRide(
            widget.token,
            widget.rideUuid,
          );
          break;
        case _RideStartAction.markArrived:
          session = await RideService.arriveAtStart(
            widget.token,
            widget.rideUuid,
          );
          break;
        case _RideStartAction.beginJourney:
          session = await RideService.startRideSession(
            widget.token,
            widget.rideUuid,
          );
          break;
        case _RideStartAction.waitForCaptain:
          _showSnack("Waiting for the captain to start the ride");
          break;
        case _RideStartAction.openLiveRide:
          _maybeOpenLiveRide();
          break;
        case _RideStartAction.refresh:
          await _loadSession();
          break;
        case _RideStartAction.completed:
        case _RideStartAction.cancelled:
          break;
      }

      if (!mounted || session == null) return;
      setState(() {
        _session = session;
      });
      _ensureEnRouteLocationSync();
      _maybeOpenLiveRide(session);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _dragPosition = 0;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst("Exception: ", ""))),
    );
  }

  void _handleTopToast(String previousState, String nextState) {
    if (previousState == nextState) {
      return;
    }

    if (nextState == "AT_START_POINT") {
      _showTopBanner("You are at the meeting point");
      return;
    }

    if (nextState == "EN_ROUTE") {
      _showTopBanner("Ride to meetup is live");
    }
  }

  void _showTopBanner(String message) {
    _topToastTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _topToastMessage = message;
      _showTopToast = true;
    });
    _topToastTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _showTopToast = false;
      });
    });
  }

  void _showRideHelp(AppThemeConfig theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: theme.primary),
                  const SizedBox(width: 10),
                  Text(
                    "Ride Flow",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 22,
                      letterSpacing: 1.1,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _HelpItem(
                number: 1,
                title: "Leave Home",
                desc:
                    "Slide start when you head to the meeting point. Your personal timer starts here.",
                theme: theme,
              ),
              const SizedBox(height: 16),
              _HelpItem(
                number: 2,
                title: "Follow Live Route",
                desc:
                    "The live map keeps your current position and meetup target in focus while you travel.",
                theme: theme,
              ),
              const SizedBox(height: 16),
              _HelpItem(
                number: 3,
                title: "Check In",
                desc:
                    "When you reach the meeting point, slide again to mark arrival and wait for the main ride start.",
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel() {
    switch (_rideStatus) {
      case "PARTIAL_STARTED":
        return "EN ROUTE";
      case "READY_TO_START":
        return "READY";
      default:
        return _rideStatus;
    }
  }

  Color _statusColor() {
    switch (_rideStatus) {
      case "ACTIVE":
        return Colors.green;
      case "READY_TO_START":
        return Colors.blue;
      case "PARTIAL_STARTED":
        return Colors.orange;
      case "COMPLETED":
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "");
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "");
  }

  String _formatDurationSeconds(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final remainingSeconds = duration.inSeconds % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    if (minutes > 0) {
      return "${minutes}m ${remainingSeconds}s";
    }
    return "${remainingSeconds}s";
  }

  String _formatElapsedDuration(DateTime startedAt, [DateTime? endedAt]) {
    final end = endedAt ?? DateTime.now();
    return _formatDurationSeconds(
      end.difference(startedAt).inSeconds.clamp(0, 2147483647),
    );
  }

  void _manageRide(AppThemeConfig theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          _rideManagementTitle,
          style: TextStyle(color: theme.textPrimary),
        ),
        content: Text(
          _rideManagementDescription,
          style: TextStyle(color: theme.textPrimary.withValues(alpha: 0.65)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              if (_hasRideStarted) {
                _completeRide();
              } else {
                _cancelRide();
              }
            },
            child: Text(_rideManagementConfirmLabel),
          ),
        ],
      ),
    );
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
            actions: [
              IconButton(
                onPressed: _fetching ? null : _loadSession,
                icon: Icon(Icons.refresh, color: theme.textPrimary),
              ),
              IconButton(
                onPressed: () => _showRideHelp(theme),
                icon: Icon(Icons.lightbulb_outline, color: theme.textPrimary),
              ),
              if (_showRideManagementAction)
                IconButton(
                  onPressed: _loading ? null : () => _manageRide(theme),
                  icon: const Icon(Icons.stop_circle, color: Colors.red),
                ),
            ],
          ),
          body: _fetching && _session == null
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _isOngoingToMeeting
                          ? _ongoingRideContent(theme)
                          : _preStartContent(theme),
                    ),
                    if (_topToastMessage != null)
                      IgnorePointer(
                        ignoring: true,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: AnimatedSlide(
                              offset: _showTopToast
                                  ? Offset.zero
                                  : const Offset(0, -0.25),
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              child: AnimatedOpacity(
                                opacity: _showTopToast ? 1 : 0,
                                duration: const Duration(milliseconds: 350),
                                child: _topToastBanner(
                                  theme,
                                  _topToastMessage!,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _preStartContent(AppThemeConfig theme) {
    return Column(
      children: [
        _rideCard(theme),
        const SizedBox(height: 20),
        _liveProgress(theme),
        const SizedBox(height: 20),
        _slider(theme),
        if (_currentUserRideStartedAt != null) ...[
          const SizedBox(height: 16),
          _individualRideTimer(theme),
        ],
      ],
    );
  }

  Widget _ongoingRideContent(AppThemeConfig theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: theme.surface,
            border: Border.all(color: theme.primary.withValues(alpha: 0.24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _phaseTitle,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 22,
                        letterSpacing: 1.1,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(
                        color: _statusColor(),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _liveProgress(theme),
        const SizedBox(height: 12),
        _liveRouteMap(theme),
        const SizedBox(height: 14),
        _slider(theme),
      ],
    );
  }

  Widget _rideCard(AppThemeConfig theme) {
    final statusColor = _statusColor();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.surface,
        border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _title,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 28,
                    letterSpacing: 1.2,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _info(Icons.calendar_today, "Date", widget.rideDate, theme),
              _info(Icons.access_time, "Time", widget.rideTime, theme),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _info(Icons.location_on, "Meetup", _meetingPoint, theme),
              _info(
                Icons.people,
                "Riders",
                "$_participantsCount joined",
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(
    IconData icon,
    String label,
    String value,
    AppThemeConfig theme,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveProgress(AppThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Live Progress",
                style: GoogleFonts.bebasNeue(
                  fontSize: 18,
                  letterSpacing: 1.1,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              CircleAvatar(radius: 4, backgroundColor: theme.primary),
            ],
          ),
          const SizedBox(height: 10),
          _personalTimerSummary(theme),
          const SizedBox(height: 10),
          Row(
            children: [
              _progressTile(
                Icons.navigation_outlined,
                "En Route",
                _enRouteCount,
                theme.secondary,
                theme,
              ),
              _progressTile(
                Icons.location_on_outlined,
                "At Start",
                _atStartCount,
                Colors.amber,
                theme,
              ),
              _progressTile(
                Icons.two_wheeler,
                "In Ride",
                _inRideCount,
                theme.primary,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _personalTimerSummary(AppThemeConfig theme) {
    final startedAt = _currentUserRideStartedAt;
    final arrivedAt = _currentUserArrivedAtStartAt;
    final loggedDuration = _currentUserTimeToMeetingSeconds;

    String timerValue = "--";

    if (startedAt != null && arrivedAt != null && loggedDuration != null) {
      timerValue = _formatDurationSeconds(loggedDuration);
    } else if (startedAt != null) {
      timerValue = _formatElapsedDuration(startedAt);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, color: theme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                "Personal Ride Timer",
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            timerValue,
            style: GoogleFonts.bebasNeue(
              fontSize: 26,
              letterSpacing: 1.1,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressTile(
    IconData icon,
    String label,
    int count,
    Color color,
    AppThemeConfig theme,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: theme.textPrimary.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveRouteMap(AppThemeConfig theme) {
    final current = _mapCurrentLocation;
    final meeting = _meetingPointLocation;
    final meetingLat = _toDouble(meeting?["latitude"]);
    final meetingLng = _toDouble(meeting?["longitude"]);
    final meetingTarget = meetingLat != null && meetingLng != null
        ? LatLng(meetingLat, meetingLng)
        : null;

    if (meetingTarget == null) {
      return _mapFallbackCard(
        theme,
        title: "Live Route",
        message: "Meeting point coordinates are not available yet.",
      );
    }

    if (current == null) {
      return _mapFallbackCard(
        theme,
        title: "Live Route",
        message:
            "Enable location access to see your live route to $_meetingPoint.",
      );
    }

    return Container(
      height: 380,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primary.withValues(alpha: 0.18)),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: current,
              initialZoom: 13.5,
              initialCameraFit: CameraFit.coordinates(
                coordinates: [current, meetingTarget],
                padding: const EdgeInsets.all(44),
                maxZoom: 14.5,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.ridersclub.throttle_ui",
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [current, meetingTarget],
                    strokeWidth: 5,
                    color: theme.primary,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: current,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  Marker(
                    point: meetingTarget,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55FF5252),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const RichAttributionWidget(
                popupInitialDisplayDuration: Duration.zero,
                attributions: [TextSourceAttribution("© OpenStreetMap")],
              ),
            ],
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.64),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_outlined, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Live Route",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "Heading to $_meetingPoint",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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
    );
  }

  Widget _mapFallbackCard(
    AppThemeConfig theme, {
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.bebasNeue(
              fontSize: 22,
              letterSpacing: 1.1,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topToastBanner(AppThemeConfig theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2015).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322C55E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: const Color(0xFF4ADE80),
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.bebasNeue(
                color: const Color(0xFF86EFAC),
                fontSize: 20,
                letterSpacing: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _individualRideTimer(AppThemeConfig theme) {
    final startedAt = _currentUserRideStartedAt;
    final arrivedAt = _currentUserArrivedAtStartAt;
    final timeToMeetingSeconds = _currentUserTimeToMeetingSeconds;

    String subtitle =
        "Your personal ride timer started when you left for the meetup.";
    if (arrivedAt != null && timeToMeetingSeconds != null) {
      subtitle =
          "You reached the meeting point in ${_formatDurationSeconds(timeToMeetingSeconds)}.";
    } else if (startedAt != null) {
      subtitle =
          "Started at ${TimeOfDay.fromDateTime(startedAt).format(context)}.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.timer_outlined, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Personal Ride Timer",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.68),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(AppThemeConfig theme) {
    final double maxWidth = MediaQuery.of(context).size.width - 32;
    const double thumbSize = 60;
    final double maxDrag = maxWidth - thumbSize - 10;
    final double progress = (_dragPosition / maxDrag).clamp(0.0, 1.0);

    return Container(
      width: maxWidth,
      height: 70,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _dragPosition + (thumbSize / 2) + 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.05),
                    theme.primary.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: (1.0 - progress * 1.8).clamp(0.0, 1.0),
              child: Text(
                _loading ? "UPDATING..." : _primaryActionLabel,
                style: GoogleFonts.bebasNeue(
                  fontSize: 22,
                  color: theme.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: _dragPosition,
            child: GestureDetector(
              onHorizontalDragStart: _canSlideAction
                  ? (_) => setState(() => _isDragging = true)
                  : null,
              onHorizontalDragUpdate: _canSlideAction
                  ? (details) {
                      setState(() {
                        _dragPosition += details.delta.dx;
                        _dragPosition = _dragPosition.clamp(0, maxDrag);
                      });
                    }
                  : null,
              onHorizontalDragEnd: _canSlideAction
                  ? (_) {
                      setState(() => _isDragging = false);
                      if (_dragPosition >= maxDrag * 0.82) {
                        setState(() => _dragPosition = maxDrag);
                        _performPrimaryAction();
                      } else {
                        setState(() => _dragPosition = 0);
                      }
                    }
                  : null,
              child: AnimatedScale(
                scale: _isDragging ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _canSlideAction
                        ? theme.primary
                        : theme.textPrimary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _RideStartAction {
  openLiveRide,
  completed,
  cancelled,
  startToMeeting,
  markArrived,
  beginJourney,
  waitForCaptain,
  refresh,
}

class _HelpItem extends StatelessWidget {
  final int number;
  final String title;
  final String desc;
  final AppThemeConfig theme;

  const _HelpItem({
    required this.number,
    required this.title,
    required this.desc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            "$number",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
