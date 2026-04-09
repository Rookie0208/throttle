import 'package:flutter/material.dart';
import 'package:throttle_ui/app/theme/app_colors.dart';
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
  bool _showSosActions = false;
  String? _activeEmergencyAlert;
  String? _activeEmergencyResolution;

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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst("Exception: ", ""))),
    );
  }

  Future<void> _showSosConfirmationModal(String label) async {
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("SOS Sent"),
        content: Text(
          "Your alert \"$label\" has been registered and will be visible on the live ride screen.",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pop();
    await dialogFuture;
  }

  Future<void> _showEmergencySosPrompt() async {
    bool canceled = false;
    final dialogFuture = showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Emergency SOS"),
          content: const Text(
            "Sending SOS to all riders",
            style: TextStyle(color: AppColors.textSecondary),
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
      setState(() {
        _activeEmergencyAlert = "Emergency SOS sent to all riders";
        _activeEmergencyResolution = null;
      });
    }
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
    final emergencyMessage = _activeEmergencyAlert;

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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
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
              Container(
                height: 220,
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
              if (emergencyMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.warning, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text(
                              "Emergency Alert",
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emergencyMessage,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        if (_canManageRide) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _activeEmergencyResolution = "Accepted";
                                    });
                                    _showSnack("SOS accepted");
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
                                    setState(() {
                                      _activeEmergencyResolution = "Rejected";
                                    });
                                    _showSnack("SOS rejected");
                                  },
                                  child: const Text("Reject"),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_activeEmergencyResolution != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            "Status: $_activeEmergencyResolution",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.campaign,
                      color: AppColors.primary,
                      size: 24,
                    ),
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
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
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
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
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
                                _loading
                                    ? "Marking..."
                                    : "Hold to Mark Reached",
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
                        await _showSosConfirmationModal(label);
                        if (!mounted) return;
                        setState(() {
                          _activeEmergencyAlert = label;
                        });
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
<<<<<<< HEAD
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
=======
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
                  onPressed: _loading ? null : _showEmergencySosPrompt,
                  child: const Icon(Icons.dangerous, size: 28),
                ),
              ),
            ],
          ),
        ),
>>>>>>> amitThrottle
      ],
    );
  }
}
