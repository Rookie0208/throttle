import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';
import 'package:throttle_ui/features/rides/presentation/screens/live_ride_screen.dart';

class RideStartScreen extends StatefulWidget {
  final String groupName;
  final String rideDate;
  final String rideTime;
  final String location;
  final int memberCount;
  final String? token;
  final String? rideUuid;

  const RideStartScreen({
    super.key,
    required this.groupName,
    required this.rideDate,
    required this.rideTime,
    required this.location,
    required this.memberCount,
    this.token,
    this.rideUuid,
  });

  @override
  State<RideStartScreen> createState() => _RideStartScreenState();
}

class _RideStartScreenState extends State<RideStartScreen> {
  double dragPosition = 0;
  bool _loading = false;
  bool _fetchingSession = false;
  Map<String, dynamic>? _session;

  bool get _hasRideSession => widget.token != null && widget.rideUuid != null;

  bool get _canManageRide =>
      (_session?["currentUserCaptain"] == true) ||
      {
        "CAPTAIN",
        "ADMIN",
        "CO_CAPTAIN",
      }.contains((_session?["currentUserRole"] ?? "").toString().toUpperCase());

  @override
  void initState() {
    super.initState();
    if (_hasRideSession) {
      _loadSession();
    }
  }

  Future<void> _loadSession() async {
    setState(() => _fetchingSession = true);
    try {
      final session = await RideService.fetchRideSession(
        widget.token!,
        widget.rideUuid!,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _fetchingSession = false);
      }
    }
  }

  Future<void> _runAction(
    Future<Map<String, dynamic>> Function() action, {
    bool openActiveRide = false,
  }) async {
    setState(() => _loading = true);
    try {
      final session = await action();
      if (!mounted) return;
      setState(() {
        _session = session;
      });
      if (openActiveRide ||
          (_session?["rideStatus"] ?? "").toString().toUpperCase() ==
              "ACTIVE") {
        _openActiveRide();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragPosition += details.delta.dx;
      if (dragPosition < 0) dragPosition = 0;
      if (dragPosition > 260) dragPosition = 260;
    });
  }

  void _handleDragEnd() {
    if (dragPosition > 250) {
      _startRideFallback();
    } else {
      setState(() {
        dragPosition = 0;
      });
    }
  }

  void _startRideFallback() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LiveRideScreen(groupName: widget.groupName, onEndRide: () {}),
      ),
    );
  }

  void _openActiveRide() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveRideScreen(
          groupName: (_session?["title"] ?? widget.groupName).toString(),
          onEndRide: () {},
          token: widget.token,
          rideUuid: widget.rideUuid,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst("Exception: ", ""))),
    );
  }

  String _displayDate() {
    final raw = _session?["scheduledStartTime"]?.toString();
    if (raw == null || raw.isEmpty) return widget.rideDate;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return widget.rideDate;
    return DateFormat("dd MMM yyyy").format(parsed.toLocal());
  }

  String _displayTime() {
    final raw = _session?["scheduledStartTime"]?.toString();
    if (raw == null || raw.isEmpty) return widget.rideTime;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return widget.rideTime;
    return DateFormat("hh:mm a").format(parsed.toLocal());
  }

  String _displayLocation() {
    return (_session?["meetingPoint"] ?? widget.location).toString();
  }

  int _participantCount() {
    final count = _session?["participantsCount"];
    if (count is int) return count;
    return widget.memberCount;
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(color: AppColors.textMuted)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernStartFlow() {
    final rideStatus = (_session?["rideStatus"] ?? "SCHEDULED").toString();
    final currentUserState = (_session?["currentUserState"] ?? "JOINED")
        .toString();
    final normalizedUserState = currentUserState.toUpperCase();
    final enRoute = (_session?["enRouteCount"] ?? 0).toString();
    final atStart = (_session?["atStartCount"] ?? 0).toString();
    final inRide = (_session?["inRideCount"] ?? 0).toString();
    final canPartialStart = normalizedUserState == "JOINED";
    final canMarkArrived =
        normalizedUserState == "JOINED" || normalizedUserState == "EN_ROUTE";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Ride Start"),
        actions: [
          IconButton(
            onPressed: _fetchingSession ? null : _loadSession,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _fetchingSession && _session == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_session?["title"] ?? widget.groupName).toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoTile(Icons.calendar_today, "Date", _displayDate()),
                        const SizedBox(height: 8),
                        _infoTile(Icons.schedule, "Time", _displayTime()),
                        const SizedBox(height: 8),
                        _infoTile(
                          Icons.location_on,
                          "Meetup",
                          _displayLocation(),
                        ),
                        const SizedBox(height: 8),
                        _infoTile(
                          Icons.people,
                          "Riders",
                          "${_participantCount()}",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _statusChip("Ride Status", rideStatus),
                      _statusChip("My Status", currentUserState),
                      _statusChip("En Route", enRoute),
                      _statusChip("At Start", atStart),
                      _statusChip("In Ride", inRide),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (rideStatus.toUpperCase() == "ACTIVE")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _openActiveRide,
                        child: const Text("Open Active Ride"),
                      ),
                    ),
                  if (rideStatus.toUpperCase() != "ACTIVE") ...[
                    if (canPartialStart) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.white,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _loading
                              ? null
                              : () => _runAction(
                                  () => RideService.partialStartRide(
                                    widget.token!,
                                    widget.rideUuid!,
                                  ),
                                ),
                          child: const Text("Partial Start"),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (canMarkArrived) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.white,
                            side: const BorderSide(
                              color: AppColors.surfaceMuted,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _loading
                              ? null
                              : () => _runAction(
                                  () => RideService.arriveAtStart(
                                    widget.token!,
                                    widget.rideUuid!,
                                  ),
                                ),
                          child: Text(
                            normalizedUserState == "EN_ROUTE"
                                ? "Mark Arrived At Start"
                                : "Already Near Start? Mark Arrived",
                          ),
                        ),
                      ),
                      if (_canManageRide) const SizedBox(height: 12),
                    ],
                    if (_canManageRide) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _loading
                              ? null
                              : () => _runAction(
                                  () => RideService.startRideSession(
                                    widget.token!,
                                    widget.rideUuid!,
                                  ),
                                  openActiveRide: true,
                                ),
                          child: const Text("Start Ride"),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "How this works",
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _canManageRide
                              ? "Riders can partial start when leaving home, mark arrival once they reach the actual meeting point, and you can start the full ride when the group is ready."
                              : "Use Partial Start when you leave home, then Mark Arrived once you reach the actual meeting point. The captain will start the full ride for everyone.",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _legacyFlow() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Start Ride"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoTile(Icons.calendar_today, "Date", widget.rideDate),
                  const SizedBox(height: 6),
                  _infoTile(Icons.schedule, "Time", widget.rideTime),
                  const SizedBox(height: 6),
                  _infoTile(Icons.location_on, "Start", widget.location),
                  const SizedBox(height: 6),
                  _infoTile(Icons.people, "Riders", "${widget.memberCount}"),
                ],
              ),
            ),
            const Spacer(),
            const Text(
              "Slide to Start Ride",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      "START RIDE",
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Positioned(
                    left: dragPosition,
                    top: 6,
                    child: GestureDetector(
                      onHorizontalDragUpdate: _handleDragUpdate,
                      onHorizontalDragEnd: (_) => _handleDragEnd(),
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.motorcycle,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _hasRideSession ? _modernStartFlow() : _legacyFlow();
  }
}
