import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/services/location_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_realtime_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_service.dart';

class ReturnRideScreen extends StatefulWidget {
  final String groupName;
  final String token;
  final String rideUuid;

  const ReturnRideScreen({
    super.key,
    required this.groupName,
    required this.token,
    required this.rideUuid,
  });

  @override
  State<ReturnRideScreen> createState() => _ReturnRideScreenState();
}

class _ReturnRideScreenState extends State<ReturnRideScreen> {
  final RideRealtimeService _rideRealtimeService = RideRealtimeService();

  Map<String, dynamic>? _session;
  bool _loading = false;
  bool _fetching = false;
  bool _sendingLocation = false;
  bool _returnCompletedHandled = false;
  Timer? _locationSyncTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _connectRealtime();
    _loadSession();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationSyncTimer?.cancel();
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
      _ensureLocationSync();
      _handleReturnCompleted(session);
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _fetching = false);
      }
    }
  }

  void _ensureLocationSync() {
    final currentUserState = (_session?["currentUserState"] ?? "")
        .toString()
        .toUpperCase();

    if (currentUserState != "RETURN_RIDE_STARTED") {
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
    if (_sendingLocation) return;

    _sendingLocation = true;
    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        return;
      }

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
      // Location sync is best-effort during return ride.
    } finally {
      _sendingLocation = false;
    }
  }

  void _handleReturnCompleted(Map<String, dynamic> session) {
    final currentUserState = (session["currentUserState"] ?? "")
        .toString()
        .toUpperCase();

    if (_returnCompletedHandled || currentUserState != "RETURN_RIDE_COMPLETED") {
      return;
    }

    _returnCompletedHandled = true;
    _locationSyncTimer?.cancel();
    _locationSyncTimer = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSnack("Reached home");
      Navigator.pop(context, session);
    });
  }

  Future<void> _completeReturnRide() async {
    setState(() => _loading = true);
    try {
      final session = await RideService.endReturnRide(
        widget.token,
        widget.rideUuid,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
      });
      _handleReturnCompleted(session);
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst("Exception: ", ""))),
    );
  }

  DateTime? _parseDate(dynamic value) {
    final raw = value?.toString().trim() ?? "";
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return "$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance.theme;
        final session = _session ?? const <String, dynamic>{};
        final returnStartedAt = _parseDate(session["currentUserReturnStartTime"]);
        final returnEndedAt = _parseDate(session["currentUserReturnEndTime"]);
        final now = DateTime.now();
        final ridingDuration = returnStartedAt == null
            ? Duration.zero
            : (returnEndedAt ?? now).difference(returnStartedAt);
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

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            title: Text(
              "Return Ride",
              style: GoogleFonts.bebasNeue(color: theme.textPrimary),
            ),
          ),
          body: _fetching && _session == null
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.groupName,
                            style: GoogleFonts.bebasNeue(
                              color: theme.textPrimary,
                              fontSize: 26,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Return Ride",
                              style: TextStyle(
                                color: theme.textPrimary.withValues(alpha: 0.65),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              _formatDuration(ridingDuration),
                              style: GoogleFonts.bebasNeue(
                                color: theme.primary,
                                fontSize: 22,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Return route live\n$ridersWithLocation rider locations synced",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.65),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Return Timeline",
                            style: GoogleFonts.bebasNeue(
                              color: theme.textPrimary,
                              fontSize: 18,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _detailRow(
                            "Started from destination",
                            returnStartedAt == null
                                ? "-"
                                : "${returnStartedAt.day.toString().padLeft(2, '0')}/${returnStartedAt.month.toString().padLeft(2, '0')}/${returnStartedAt.year} • ${((returnStartedAt.hour % 12 == 0) ? 12 : returnStartedAt.hour % 12)}:${returnStartedAt.minute.toString().padLeft(2, '0')} ${returnStartedAt.hour >= 12 ? "PM" : "AM"}",
                            theme.textPrimary,
                          ),
                          _detailRow(
                            "Current state",
                            (session["currentUserState"] ?? "RETURN_RIDE_STARTED")
                                .toString()
                                .replaceAll("_", " "),
                            theme.primary,
                          ),
                          _detailRow(
                            "Total return time",
                            _formatDuration(ridingDuration),
                            theme.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _completeReturnRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_loading ? "Updating..." : "Reached Home"),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: valueColor.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
