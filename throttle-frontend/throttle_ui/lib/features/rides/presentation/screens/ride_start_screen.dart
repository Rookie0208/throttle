import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
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

  bool _expanded = false;
  bool _loading = false;
  bool _fetching = false;
  bool _isDragging = false;
  bool _navigatingToLiveRide = false;
  double _dragPosition = 0;
  Map<String, dynamic>? _session;

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

  @override
  void initState() {
    super.initState();
    _connectRealtime();
    _loadSession();
  }

  @override
  void dispose() {
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
      final session = await RideService.fetchRideSession(
        widget.token,
        widget.rideUuid,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
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
              if (_showRideManagementAction)
                IconButton(
                  onPressed: _loading ? null : () => _manageRide(theme),
                  icon: const Icon(Icons.stop_circle, color: Colors.red),
                ),
            ],
          ),
          body: _fetching && _session == null
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
                      if (_currentUserState == "AT_START_POINT") ...[
                        const SizedBox(height: 20),
                        _arrivalMessage(theme),
                      ],
                      const SizedBox(height: 20),
                      _accordion(theme),
                    ],
                  ),
                ),
        );
      },
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
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
          const SizedBox(height: 16),
          Row(
            children: [
              _progressTile(
                Icons.navigation,
                "En Route",
                _enRouteCount,
                theme.secondary,
                theme,
              ),
              _progressTile(
                Icons.location_on,
                "At Start",
                _atStartCount,
                Colors.amber,
                theme,
              ),
              _progressTile(
                Icons.navigation,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.textPrimary.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrivalMessage(AppThemeConfig theme) {
    final subtitle = _canManageRide
        ? "Start the full ride when everyone is ready"
        : "Waiting for the captain to begin the journey";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You are at the meeting point",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textPrimary.withValues(alpha: 0.65),
                    fontSize: 14,
                  ),
                ),
              ],
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

  Widget _accordion(AppThemeConfig theme) {
    return Column(
      children: [
        ListTile(
          tileColor: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: () => setState(() => _expanded = !_expanded),
          leading: Icon(Icons.info, color: theme.primary),
          title: Text(
            "How this works",
            style: GoogleFonts.bebasNeue(
              fontSize: 18,
              letterSpacing: 1.1,
              color: theme.textPrimary,
            ),
          ),
          subtitle: Text(
            _expanded ? "Tap to hide" : "Tap to learn more",
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.65),
              fontFamily: 'Inter',
            ),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: theme.textPrimary,
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _HelpItem(
                  number: 1,
                  title: "Start Ride",
                  theme: theme,
                  desc:
                      "Slide \"Start Ride\" when you're leaving home. This updates the shared ride session for everyone.",
                ),
                const SizedBox(height: 16),
                _HelpItem(
                  number: 2,
                  title: "Mark Arrived",
                  theme: theme,
                  desc:
                      "Once you reach the meetup point, slide \"Mark Arrived\" so the ride status is synced for the group.",
                ),
                const SizedBox(height: 16),
                _HelpItem(
                  number: 3,
                  title: "Begin Journey",
                  theme: theme,
                  desc:
                      "When the group is ready, the ride captain can start the full ride and everyone moves into the live console.",
                ),
              ],
            ),
          ),
      ],
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
