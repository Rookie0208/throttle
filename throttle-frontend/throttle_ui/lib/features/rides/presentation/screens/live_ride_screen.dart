import 'package:flutter/material.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
import 'package:throttle_ui/core/services/location_service.dart';
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
  bool _loading = false;
  bool _fetching = false;
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

  Future<void> _updateMyLocation() async {
    await _withLoading(() async {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        throw Exception("Location unavailable or permission denied");
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
      _showSnack("Live location updated");
    });
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

  Future<void> _sendBroadcast() async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Captain Broadcast"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: AppColors.white),
          decoration: const InputDecoration(
            hintText: "Send a ride update to everyone",
            hintStyle: TextStyle(color: AppColors.textHint),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Send"),
          ),
        ],
      ),
    );

    if (message == null || message.trim().isEmpty) return;

    await _withLoading(() async {
      await RideService.sendRideAnnouncement(
        widget.token!,
        widget.rideUuid!,
        message,
      );
      await _loadSession();
    });
  }

  Future<void> _completeRide() async {
    await _withLoading(() async {
      await RideService.completeRide(widget.token!, widget.rideUuid!);
      await _loadSession();
      if (!mounted) return;
      _showSnack("Ride completed");
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst("Exception: ", ""))),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionView() {
    final session = _session ?? const <String, dynamic>{};
    final participants = List<Map<String, dynamic>>.from(
      session["participants"] ?? const [],
    );
    final checkpoints = List<Map<String, dynamic>>.from(
      session["checkpoints"] ?? const [],
    );

    return RefreshIndicator(
      onRefresh: _loadSession,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (session["title"] ?? widget.groupName).toString(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Status: ${(session["rideStatus"] ?? "ACTIVE").toString()}",
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _metric(
                      "En Route",
                      (session["enRouteCount"] ?? 0).toString(),
                    ),
                    _metric(
                      "At Start",
                      (session["atStartCount"] ?? 0).toString(),
                    ),
                    _metric(
                      "In Ride",
                      (session["inRideCount"] ?? 0).toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Captain Broadcast",
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (session["latestBroadcastMessage"] ??
                          "No broadcast sent yet.")
                      .toString(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Checkpoint Progress",
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (checkpoints.isEmpty)
                  const Text(
                    "No checkpoints configured yet.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ...checkpoints.map(
                  (checkpoint) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              checkpoint["checkpointStatus"] == "CURRENT"
                              ? AppColors.primary
                              : AppColors.surfaceMuted,
                          child: Text(
                            "${checkpoint["sequence"] ?? 0}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (checkpoint["title"] ?? "Checkpoint").toString(),
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ),
                        Text(
                          (checkpoint["checkpointStatus"] ?? "UPCOMING")
                              .toString(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Participants",
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (participants.isEmpty)
                  const Text(
                    "No riders found.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ...participants
                    .take(8)
                    .map(
                      (participant) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          [
                                (participant["firstName"] ?? "").toString(),
                                (participant["lastName"] ?? "").toString(),
                              ].join(" ").trim().isEmpty
                              ? (participant["riderId"] ?? "Rider").toString()
                              : [
                                  (participant["firstName"] ?? "").toString(),
                                  (participant["lastName"] ?? "").toString(),
                                ].join(" ").trim(),
                          style: const TextStyle(color: AppColors.white),
                        ),
                        subtitle: Text(
                          "${participant["role"] ?? "RIDER"} • ${participant["participantState"] ?? "JOINED"}",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: participant["lastLocationUpdatedAt"] != null
                            ? const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: OutlinedButton(
                  onPressed: _loading ? null : _updateMyLocation,
                  child: const Text("Update My Location"),
                ),
              ),
              if (_canManageRide)
                SizedBox(
                  width: 170,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _advanceCheckpoint,
                    child: const Text("Advance Checkpoint"),
                  ),
                ),
              if (_canManageRide)
                SizedBox(
                  width: 170,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _sendBroadcast,
                    child: const Text("Broadcast"),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
              ),
              onPressed: _loading || !_canManageRide ? null : _completeRide,
              child: const Text("Complete Ride"),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _legacyView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Text(
                "Current Speed",
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 6),
              Text(
                "45 mph",
                style: TextStyle(
                  fontSize: 32,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _hasRideSession
            ? (_fetching && _session == null
                  ? const Center(child: CircularProgressIndicator())
                  : _liveRideView())
            : _legacyView(),
      ),
    );
  }

  Widget _liveRideView() {
    final session = _session ?? const <String, dynamic>{};
    final checkpoints = List<Map<String, dynamic>>.from(
      session["checkpoints"] ?? const [],
    );
    final currentCheckpoint = checkpoints.firstWhere(
      (c) => c["checkpointStatus"] == "CURRENT",
      orElse: () => const <String, dynamic>{},
    );
    final totalCheckpoints = checkpoints.length;
    final currentIndex = currentCheckpoint["sequence"] ?? 0;

    // Calculate duration
    final startTimeStr = session["startTime"];
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
        // Top bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (session["title"] ?? widget.groupName).toString(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Duration",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    durationStr,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Map preview
        Container(
          height: 150,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              "Map Preview\n(All riders locations)",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Broadcast card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Captain's Broadcast",
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (session["latestBroadcastMessage"] ??
                              "No broadcast sent yet.")
                          .toString(),
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
        const SizedBox(height: 16),
        // Checkpoints
        Container(
          height: 140,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Checkpoints",
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "#$currentIndex/$totalCheckpoints",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (currentCheckpoint.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (currentCheckpoint["title"] ?? "Next Checkpoint")
                            .toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.directions,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Distance: ${currentCheckpoint["estimatedTime"] ?? "N/A"}",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onLongPress: _loading ? null : _advanceCheckpoint,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _loading
                            ? AppColors.surfaceMuted
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _loading ? "Marking..." : "Hold to Mark Reached",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const Center(
                  child: Text(
                    "No active checkpoint",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // SOS Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // TODO: Implement SOS
              },
              child: const Text(
                "SOS / Emergency",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
