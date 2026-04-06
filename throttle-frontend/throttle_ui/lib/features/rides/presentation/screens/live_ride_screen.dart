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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text("${widget.groupName} - Live Ride"),
        actions: _hasRideSession
            ? [
                IconButton(
                  onPressed: _fetching ? null : _loadSession,
                  icon: const Icon(Icons.refresh),
                ),
              ]
            : null,
      ),
      body: _hasRideSession
          ? (_fetching && _session == null
                ? const Center(child: CircularProgressIndicator())
                : _sessionView())
          : _legacyView(),
    );
  }
}
