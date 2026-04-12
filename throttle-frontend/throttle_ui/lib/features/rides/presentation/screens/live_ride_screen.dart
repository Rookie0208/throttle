import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/services/location_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_realtime_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';

class LiveRideScreen extends StatefulWidget {
  final String groupName;
  final VoidCallback onEndRide;
  final String? token;
  final String? rideUuid;

  const LiveRideScreen({
    super.key,
    required this.groupName,
    required this.onEndRide,
    this.token,
    this.rideUuid,
  });

  @override
  State<LiveRideScreen> createState() => _LiveRideScreenState();
}

class _LiveRideScreenState extends State<LiveRideScreen> {
  final RideRealtimeService _rideRealtimeService = RideRealtimeService();

  bool _loading = false;
  bool _fetching = false;
  bool _sendingLocation = false;
  bool _rideClosedHandled = false;
  Map<String, dynamic>? _session;
  bool _showSosActions = false;
  Timer? _locationSyncTimer;

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
      _connectRealtime();
      _loadSession();
    }
  }

  @override
  void dispose() {
    _locationSyncTimer?.cancel();
    _rideRealtimeService.disconnect();
    super.dispose();
  }

  void _connectRealtime() {
    _rideRealtimeService.connect(
      token: widget.token!,
      rideUuid: widget.rideUuid!,
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
        widget.token!,
        widget.rideUuid!,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
      _ensureLocationSync();
      _handleCompletedRide(session);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _fetching = false);
      }
    }
  }

  Future<void> _withLoading(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _advanceCheckpoint() async {
    await _withLoading(() async {
      final session = await RideService.advanceCheckpoint(
        widget.token!,
        widget.rideUuid!,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
    });
  }

  void _ensureLocationSync() {
    final rideStatus = (_session?["rideStatus"] ?? "").toString().toUpperCase();
    final currentUserState = (_session?["currentUserState"] ?? "")
        .toString()
        .toUpperCase();

    final shouldSync =
        rideStatus == "ACTIVE" &&
        currentUserState != "DROPPED" &&
        currentUserState != "COMPLETED";

    if (!shouldSync) {
      _locationSyncTimer?.cancel();
      _locationSyncTimer = null;
      return;
    }

    if (_locationSyncTimer != null) {
      return;
    }

    unawaited(_syncCurrentLocation());
    _locationSyncTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_syncCurrentLocation()),
    );
  }

  Future<void> _syncCurrentLocation() async {
    if (!_hasRideSession || _sendingLocation) {
      return;
    }

    _sendingLocation = true;
    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        return;
      }

      final session = await RideService.updateRideLocation(
        widget.token!,
        widget.rideUuid!,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _session = session;
      });
    } catch (_) {
      // Best-effort location syncing. Session websocket updates remain the fallback.
    } finally {
      _sendingLocation = false;
    }
  }

  void _handleCompletedRide(Map<String, dynamic> session) {
    final rideStatus = (session["rideStatus"] ?? "").toString().toUpperCase();
    if (_rideClosedHandled || rideStatus != "COMPLETED") {
      return;
    }

    _rideClosedHandled = true;
    _locationSyncTimer?.cancel();
    _locationSyncTimer = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSnack("Ride ended by captain");
      Navigator.pop(context);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst("Exception: ", ""))),
    );
  }

  Future<void> _showSosConfirmationModal(
    String label,
    AppThemeConfig theme,
  ) async {
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          "SOS Sent",
          style: GoogleFonts.bebasNeue(
            color: theme.textPrimary,
            letterSpacing: 1.1,
          ),
        ),
        content: Text(
          "Your alert \"$label\" has been registered and will be visible on the live ride screen.",
          style: TextStyle(color: theme.textPrimary.withValues(alpha: 0.65)),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pop();
    await dialogFuture;
  }

  Future<void> _showEmergencySosPrompt(AppThemeConfig theme) async {
    bool canceled = false;
    final dialogFuture = showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.surface,
          title: Text(
            "Emergency SOS",
            style: GoogleFonts.bebasNeue(
              color: theme.textPrimary,
              letterSpacing: 1.1,
            ),
          ),
          content: Text(
            "Sending SOS to all riders",
            style: TextStyle(color: theme.textPrimary.withValues(alpha: 0.65)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                canceled = true;
                Navigator.of(context).pop(false);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!canceled && mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(true);
      }
    });

    final result = await dialogFuture;
    if (result == true) {
      await _sendSos("Emergency SOS sent to all riders");
    }
  }

  Future<void> _sendSos(String message) async {
    await _withLoading(() async {
      final session = await RideService.sendSos(
        widget.token!,
        widget.rideUuid!,
        message,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
    });
  }

  Future<void> _resolveSos(String resolution) async {
    await _withLoading(() async {
      final session = await RideService.resolveSos(
        widget.token!,
        widget.rideUuid!,
        resolution,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
      _showSnack(
        resolution == "ACCEPTED" ? "SOS accepted" : "SOS rejected",
      );
    });
  }

  Future<void> _completeRide() async {
    if (!_canManageRide) {
      _showSnack("Only captain/admin can end this ride");
      return;
    }

    await _withLoading(() async {
      await RideService.completeRide(widget.token!, widget.rideUuid!);
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  void _endRide(AppThemeConfig theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text("End Ride", style: TextStyle(color: theme.textPrimary)),
        content: Text(
          "Are you sure you want to end this ride?",
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
              _completeRide();
            },
            child: const Text("End Ride"),
          ),
        ],
      ),
    );
  }

  Widget _legacyView(AppThemeConfig theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Text(
                "Current Speed",
                style: TextStyle(
                  color: theme.textPrimary.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "45 mph",
                style: GoogleFonts.bebasNeue(
                  fontSize: 48,
                  color: theme.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          ),
          onPressed: widget.onEndRide,
          child: const Text("End Ride"),
        ),
        const SizedBox(height: 40),
      ],
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
          appBar: _hasRideSession
              ? AppBar(
                  backgroundColor: theme.background,
                  elevation: 0,
                  actions: [
                    IconButton(
                      onPressed: _fetching ? null : _loadSession,
                      icon: Icon(Icons.refresh, color: theme.textPrimary),
                    ),
                    IconButton(
                      onPressed: _loading ? null : () => _endRide(theme),
                      icon: const Icon(Icons.stop_circle, color: Colors.red),
                    ),
                  ],
                )
              : null,
          body: SafeArea(
            child: _hasRideSession
                ? (_fetching && _session == null
                      ? Center(
                          child: CircularProgressIndicator(
                            color: theme.primary,
                          ),
                        )
                      : _liveRideView(theme))
                : _legacyView(theme),
          ),
        );
      },
    );
  }

  Widget _liveRideView(AppThemeConfig theme) {
    final session = _session ?? const <String, dynamic>{};
    final checkpoints = List<Map<String, dynamic>>.from(
      session["checkpoints"] ?? const [],
    );
    final currentCheckpoint = checkpoints.firstWhere(
      (c) =>
          (c["checkpointStatus"] ?? "").toString().toUpperCase() == "CURRENT",
      orElse: () => const <String, dynamic>{},
    );
    final totalCheckpoints = checkpoints.length;
    final currentIndex = currentCheckpoint["sequence"] ?? 0;
    final emergencyMessage = (session["activeSosMessage"] ?? "").toString().trim();
    final activeSosAt = (session["activeSosAt"] ?? "").toString();
    final activeSosRaisedByName =
        (session["activeSosRaisedByName"] ?? "A rider").toString();
    final currentUserUuid = (session["currentUserUuid"] ?? "").toString();
    final activeSosRaisedByUuid =
        (session["activeSosRaisedByUuid"] ?? "").toString();
    final activeSosRaisedByLabel =
        currentUserUuid.isNotEmpty && currentUserUuid == activeSosRaisedByUuid
        ? "you"
        : activeSosRaisedByName;
    final activeSosResolution = (session["activeSosResolution"] ?? "")
        .toString()
        .trim();
    final activeSosResolvedByName =
        (session["activeSosResolvedByName"] ?? "").toString().trim();
    final participants = List<Map<String, dynamic>>.from(
      session["participants"] ?? const [],
    );
    final ridersWithLocation = participants
        .where(
          (participant) =>
              participant["lastLatitude"] != null &&
              participant["lastLongitude"] != null,
        )
        .length;

    // Calculate duration
    final startTimeStr = session["rideStartedAt"] ?? session["scheduledStartTime"];
    Duration duration = Duration.zero;
    if (startTimeStr != null) {
      try {
        final startTime = DateTime.parse(startTimeStr);
        duration = DateTime.now().difference(startTime);
      } catch (_) {}
    }
    final durationStr =
        "${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}";

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (session["title"] ?? widget.groupName).toString(),
                      style: GoogleFonts.bebasNeue(
                        color: theme.textPrimary,
                        fontSize: 24,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Duration",
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          durationStr,
                          style: GoogleFonts.bebasNeue(
                            color: theme.textPrimary,
                            fontSize: 18,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 220,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Map Preview\n$ridersWithLocation rider locations synced",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff8C95A8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (emergencyMessage.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(
                              "Emergency Alert",
                              style: GoogleFonts.bebasNeue(
                                color: theme.textPrimary,
                                fontSize: 18,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emergencyMessage,
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.65),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Raised by $activeSosRaisedByLabel${activeSosAt.isNotEmpty ? " at $activeSosAt" : ""}",
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                        if (_canManageRide &&
                            activeSosResolution.isEmpty &&
                            currentUserUuid.isNotEmpty &&
                            currentUserUuid != activeSosRaisedByUuid) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () {
                                    _resolveSos("ACCEPTED");
                                  },
                                  child: const Text("Accept"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () {
                                    _resolveSos("REJECTED");
                                  },
                                  child: const Text("Reject"),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (activeSosResolution.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            activeSosResolvedByName.isNotEmpty
                                ? "Status: $activeSosResolution by $activeSosResolvedByName"
                                : "Status: $activeSosResolution",
                            style: TextStyle(
                              color: theme.textPrimary.withValues(alpha: 0.65),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.campaign, color: theme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Captain's Broadcast",
                            style: GoogleFonts.bebasNeue(
                              color: theme.textPrimary,
                              fontSize: 18,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (session["latestBroadcastMessage"] ??
                                    "No broadcast sent yet.")
                                .toString(),
                            style: TextStyle(
                              color: theme.textPrimary.withValues(alpha: 0.65),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Checkpoints",
                          style: GoogleFonts.bebasNeue(
                            color: theme.textPrimary,
                            fontSize: 18,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          "#$currentIndex/$totalCheckpoints",
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (currentCheckpoint.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: theme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (currentCheckpoint["title"] ?? "Next Checkpoint")
                                  .toString(),
                              style: GoogleFonts.bebasNeue(
                                color: theme.textPrimary,
                                fontSize: 20,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.directions,
                            color: theme.textPrimary.withValues(alpha: 0.65),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Distance: ${currentCheckpoint["estimatedTime"] ?? "N/A"}",
                            style: TextStyle(
                              color: theme.textPrimary.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_canManageRide)
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onLongPress: _loading ? null : _advanceCheckpoint,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _loading
                                    ? theme.textPrimary.withValues(alpha: 0.1)
                                    : theme.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  if (!_loading)
                                    BoxShadow(
                                      color: theme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _loading
                                      ? "Marking..."
                                      : "Hold to Mark Reached",
                                  style: GoogleFonts.bebasNeue(
                                    color: Colors.white,
                                    fontSize: 18,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ] else ...[
                      Center(
                        child: Text(
                          "No active checkpoint",
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showSosActions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final label in [
                  "STOP",
                  "RE-GROUP",
                  "LOST",
                  "BIKE ISSUE",
                  "EMERGENCY",
                  "NEED REFUELING",
                ])
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 64) / 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        setState(() {
                          _showSosActions = false;
                        });
                        await _showSosConfirmationModal(label, theme);
                        if (!mounted) return;
                        await _sendSos(label);
                      },
                      child: Text(label),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() => _showSosActions = !_showSosActions);
                          },
                    child: Text(
                      _showSosActions ? "Hide SOS Options" : "SOS",
                      style: GoogleFonts.bebasNeue(
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 58,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading
                      ? null
                      : () => _showEmergencySosPrompt(theme),
                  child: const Icon(
                    Icons.dangerous,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
