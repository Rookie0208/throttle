import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:throttle_ui/app/theme/theme_controller.dart';
import 'package:throttle_ui/core/services/location_service.dart';
import 'package:throttle_ui/core/services/routing_service.dart';
import 'package:throttle_ui/features/rides/data/services/ride_refresh_notifier.dart';
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

class _LiveRideScreenState extends State<LiveRideScreen>
    with TickerProviderStateMixin {
  final RideRealtimeService _rideRealtimeService = RideRealtimeService();
  final MapController _mapController = MapController();
  final latlng.Distance _distance = const latlng.Distance();

  static const double _navigationZoom = 16.4;
  static const double _routeSnapThresholdMeters = 80;

  bool _loading = false;
  bool _fetching = false;
  bool _sendingLocation = false;
  bool _rideClosedHandled = false;
  Map<String, dynamic>? _session;
  bool _isPaused = false;
  bool _showSosActions = false;
  Timer? _locationSyncTimer;
  Timer? _refreshTimer;
  Duration _totalPausedTime = Duration.zero;
  DateTime? _pauseStartTime;
  List<latlng.LatLng> _roadRoutePoints = const <latlng.LatLng>[];
  List<RoadRouteStep> _routeSteps = const <RoadRouteStep>[];
  double _routeDistanceMeters = 0;
  double _routeDurationSeconds = 0;
  bool _routeUnavailable = false;
  bool _routeLoading = false;
  bool _routeLoaded = false;
  latlng.LatLng? _currentLocation;
  double _currentSpeedMps = 0;
  double _currentHeading = 0;
  bool _isFollowingUser = true;
  bool _isVoiceMuted = false;
  latlng.LatLng? _lastRouteOrigin;
  StreamSubscription<Position>? _positionSubscription;
  AnimationController? _cameraAnimationController;
  latlng.LatLng? _cameraCenter;
  double _cameraZoom = 12.5;

  bool get _hasRideSession => widget.token != null && widget.rideUuid != null;

  String get _mapboxPublicToken =>
      dotenv.env['MAPBOX_PUBLIC_TOKEN']?.trim() ?? '';

  String get _mapboxTileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxPublicToken';

  bool get _hasMapboxToken => _mapboxPublicToken.isNotEmpty;

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
    _cameraCenter = null;
    if (_hasRideSession) {
      unawaited(_restorePauseState());
      _connectRealtime();
      _startNavigationTracking();
      _loadSession();
    }
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cameraAnimationController?.dispose();
    _positionSubscription?.cancel();
    _refreshTimer?.cancel();
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

  String? get _pauseStateKeyPrefix =>
      _hasRideSession ? "live_ride_pause_${widget.rideUuid}" : null;

  Future<void> _restorePauseState() async {
    final keyPrefix = _pauseStateKeyPrefix;
    if (keyPrefix == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final isPaused = prefs.getBool("${keyPrefix}_is_paused") ?? false;
    final totalPausedMs = prefs.getInt("${keyPrefix}_total_paused_ms") ?? 0;
    final pauseStartIso = prefs.getString("${keyPrefix}_pause_started_at");

    DateTime? pauseStartTime;
    if (pauseStartIso != null && pauseStartIso.isNotEmpty) {
      try {
        pauseStartTime = DateTime.parse(pauseStartIso);
      } catch (_) {
        pauseStartTime = null;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPaused = isPaused;
      _totalPausedTime = Duration(milliseconds: totalPausedMs);
      _pauseStartTime = isPaused ? pauseStartTime : null;
    });
  }

  Future<void> _persistPauseState() async {
    final keyPrefix = _pauseStateKeyPrefix;
    if (keyPrefix == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("${keyPrefix}_is_paused", _isPaused);
    await prefs.setInt(
      "${keyPrefix}_total_paused_ms",
      _totalPausedTime.inMilliseconds,
    );

    if (_pauseStartTime != null) {
      await prefs.setString(
        "${keyPrefix}_pause_started_at",
        _pauseStartTime!.toIso8601String(),
      );
    } else {
      await prefs.remove("${keyPrefix}_pause_started_at");
    }
  }

  Future<void> _clearPauseState() async {
    final keyPrefix = _pauseStateKeyPrefix;
    if (keyPrefix == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("${keyPrefix}_is_paused");
    await prefs.remove("${keyPrefix}_total_paused_ms");
    await prefs.remove("${keyPrefix}_pause_started_at");
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
      await _refreshNavigationRoute(force: true, sessionOverride: session);
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
      await _refreshNavigationRoute(force: true, sessionOverride: session);
    });
  }

  Future<void> _startNavigationTracking() async {
    final initialPosition = await LocationService.getCurrentLocation();
    if (!mounted) {
      return;
    }

    if (initialPosition != null) {
      _applyLivePosition(initialPosition, animateCamera: true);
      unawaited(_refreshNavigationRoute(force: true));
    }

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((position) {
          if (!mounted) {
            return;
          }
          _applyLivePosition(position, animateCamera: true);
          if (_shouldRefreshNavigationRoute()) {
            unawaited(_refreshNavigationRoute());
          }
        });
  }

  void _applyLivePosition(Position position, {required bool animateCamera}) {
    final location = latlng.LatLng(position.latitude, position.longitude);
    setState(() {
      _currentLocation = location;
      _currentSpeedMps = position.speed >= 0 ? position.speed : 0;
      _currentHeading = _normalizedHeading(position.heading);
    });

    if (animateCamera && _isFollowingUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _animateCameraTo(location, zoom: _navigationZoom);
      });
    }
  }

  bool _shouldRefreshNavigationRoute() {
    final currentLocation = _currentLocation;
    if (currentLocation == null) {
      return false;
    }
    if (!_routeLoaded || _roadRoutePoints.isEmpty || _routeUnavailable) {
      return true;
    }
    final lastRouteOrigin = _lastRouteOrigin;
    if (lastRouteOrigin == null) {
      return true;
    }
    return _distance(currentLocation, lastRouteOrigin) >= 40;
  }

  Future<void> _refreshNavigationRoute({
    bool force = false,
    Map<String, dynamic>? sessionOverride,
  }) async {
    final session = sessionOverride ?? _session;
    if (session == null) {
      return;
    }

    final waypoints = _navigationWaypointsFromSession(session);
    if (waypoints.length < 2) {
      if (!mounted) {
        return;
      }
      setState(() {
        _roadRoutePoints = const <latlng.LatLng>[];
        _routeSteps = const <RoadRouteStep>[];
        _routeDistanceMeters = 0;
        _routeDurationSeconds = 0;
        _routeLoaded = true;
        _routeLoading = false;
        _routeUnavailable = false;
      });
      return;
    }

    if (!force &&
        _lastRouteOrigin != null &&
        _currentLocation != null &&
        _distance(_currentLocation!, _lastRouteOrigin!) < 40 &&
        _roadRoutePoints.isNotEmpty &&
        !_routeUnavailable) {
      return;
    }

    if (mounted) {
      setState(() {
        _routeLoading = true;
        _routeLoaded = false;
      });
    }

    final result = await RoutingService.fetchRoadRouteDetails(waypoints);
    if (!mounted) {
      return;
    }

    setState(() {
      _roadRoutePoints = result.points
          .map((point) => latlng.LatLng(point.latitude, point.longitude))
          .toList();
      _routeSteps = result.steps;
      _routeDistanceMeters = result.distanceMeters;
      _routeDurationSeconds = result.durationSeconds;
      _routeUnavailable = result.isFallback;
      _routeLoaded = true;
      _routeLoading = false;
      _lastRouteOrigin = waypoints.first;
    });
  }

  List<latlng.LatLng> _navigationWaypointsFromSession(
    Map<String, dynamic> session,
  ) {
    final checkpoints = List<Map<String, dynamic>>.from(
      session["checkpoints"] ?? const [],
    );
    final currentUserUuid = (session["currentUserUuid"] ?? "").toString();
    final participants = List<Map<String, dynamic>>.from(
      session["participants"] ?? const [],
    );

    final remainingCheckpoints =
        checkpoints.where((checkpoint) {
          final status = (checkpoint["checkpointStatus"] ?? "")
              .toString()
              .toUpperCase();
          return status != "REACHED";
        }).toList()..sort((a, b) {
          final left = (a["sequence"] as num?)?.toInt() ?? 0;
          final right = (b["sequence"] as num?)?.toInt() ?? 0;
          return left.compareTo(right);
        });

    final points = <latlng.LatLng>[];
    final origin =
        _currentLocation ?? _currentUserLocation(participants, currentUserUuid);
    if (origin != null) {
      points.add(origin);
    }

    for (final checkpoint in remainingCheckpoints) {
      final latitude = _toDouble(checkpoint["latitude"]);
      final longitude = _toDouble(checkpoint["longitude"]);
      if (latitude == null || longitude == null) {
        continue;
      }
      final point = latlng.LatLng(latitude, longitude);
      if (points.isEmpty || _distance(points.last, point) > 10) {
        points.add(point);
      }
    }

    return points;
  }

  void _animateCameraTo(latlng.LatLng target, {required double zoom}) {
    _cameraAnimationController?.stop();
    _cameraAnimationController?.dispose();

    final startCenter = _cameraCenter ?? target;
    final startZoom = _cameraZoom;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    controller.addListener(() {
      final t = curve.value;
      final center = latlng.LatLng(
        startCenter.latitude + ((target.latitude - startCenter.latitude) * t),
        startCenter.longitude +
            ((target.longitude - startCenter.longitude) * t),
      );
      final nextZoom = startZoom + ((zoom - startZoom) * t);
      _cameraCenter = center;
      _cameraZoom = nextZoom;
      _mapController.move(center, nextZoom);
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _cameraCenter = target;
        _cameraZoom = zoom;
      }
    });

    _cameraAnimationController = controller;
    unawaited(controller.forward());
  }

  double _normalizedHeading(double heading) {
    if (heading.isNaN || heading.isInfinite || heading < 0) {
      return 0;
    }
    return heading % 360;
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
      unawaited(_refreshNavigationRoute(sessionOverride: session));
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
    unawaited(_clearPauseState());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSnack("Ride ended by captain");
      Navigator.pop(context);
    });
  }

  Future<void> _addCustomCheckpoint(AppThemeConfig theme) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          "Custom Checkpoint",
          style: GoogleFonts.bebasNeue(color: theme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            hintText: "e.g., View Point, Tea Break",
            hintStyle: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text("Mark Location"),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty) {
      await _withLoading(() async {
        // Logic: Captain adds to ride stats, Normal Rider adds to personal stats
        if (_canManageRide) {
          await RideService.addRideCheckpoint(
            widget.token!,
            widget.rideUuid!,
            title,
          );
          _showSnack("Checkpoint '$title' added to group ride");
          await _loadSession(); // Refresh to show new point
        } else {
          // Mock personal stat update for regular riders
          await Future.delayed(const Duration(seconds: 1));
          _showSnack("Point '$title' saved to your personal stats");
        }
      });
    }
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
      _showSnack(resolution == "ACCEPTED" ? "SOS accepted" : "SOS rejected");
    });
  }

  Future<void> _completeRide() async {
    if (!_canManageRide) {
      _showSnack("Only captain/admin can end this ride");
      return;
    }

    await _withLoading(() async {
      await RideService.completeRide(widget.token!, widget.rideUuid!);
      RideRefreshNotifier.notify();
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
    final bool allReached =
        checkpoints.isNotEmpty &&
        checkpoints.every(
          (c) =>
              (c["checkpointStatus"] ?? "").toString().toUpperCase() ==
              "REACHED",
        );
    final totalCheckpoints = checkpoints.length;
    final currentIndex = currentCheckpoint["sequence"] ?? 0;
    final emergencyMessage = (session["activeSosMessage"] ?? "")
        .toString()
        .trim();
    final activeSosAt = (session["activeSosAt"] ?? "").toString();
    final activeSosRaisedByName =
        (session["activeSosRaisedByName"] ?? "A rider").toString();
    final currentUserUuid = (session["currentUserUuid"] ?? "").toString();
    final activeSosRaisedByUuid = (session["activeSosRaisedByUuid"] ?? "")
        .toString();
    final activeSosRaisedByLabel =
        currentUserUuid.isNotEmpty && currentUserUuid == activeSosRaisedByUuid
        ? "you"
        : activeSosRaisedByName;
    final activeSosResolution = (session["activeSosResolution"] ?? "")
        .toString()
        .trim();
    final activeSosResolvedByName = (session["activeSosResolvedByName"] ?? "")
        .toString()
        .trim();
    final participants = List<Map<String, dynamic>>.from(
      session["participants"] ?? const [],
    );
    final currentUserLocation =
        _currentLocation ?? _currentUserLocation(participants, currentUserUuid);
    final ridersWithLocation = participants
        .where(
          (participant) =>
              participant["lastLatitude"] != null &&
              participant["lastLongitude"] != null,
        )
        .length;
    final remainingDistanceLabel = _remainingDistanceLabel(
      currentCheckpoint,
      currentUserLocation,
    );

    // Calculate duration
    final startTimeStr =
        session["rideStartedAt"] ?? session["scheduledStartTime"];
    DateTime? startTime;
    if (startTimeStr != null) {
      try {
        startTime = DateTime.parse(startTimeStr);
      } catch (_) {}
    }

    final now = DateTime.now();
    final journeyDuration = startTime != null
        ? now.difference(startTime)
        : Duration.zero;

    Duration ridingDuration = Duration.zero;
    if (startTime != null) {
      if (_isPaused && _pauseStartTime != null) {
        ridingDuration =
            _pauseStartTime!.difference(startTime) - _totalPausedTime;
      } else {
        ridingDuration = now.difference(startTime) - _totalPausedTime;
      }
    }

    String format(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      final s = d.inSeconds % 60;
      return "$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }

    // Determine descriptive labels
    String checkpointLabelText = "Checkpoint";
    if (currentIndex == 1) {
      checkpointLabelText = "Start Point";
    } else if (currentIndex == totalCheckpoints && currentIndex > 1) {
      checkpointLabelText = "Destination";
    } else if (currentIndex > 1) {
      checkpointLabelText = "Checkpoint ${currentIndex - 1}";
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              Container(
                height: 510,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildLiveRideMap(
                    theme,
                    participants: participants,
                    checkpoints: checkpoints,
                    ridersWithLocation: ridersWithLocation,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          (session["title"] ?? widget.groupName).toString(),
                          style: GoogleFonts.bebasNeue(
                            color: theme.textPrimary,
                            fontSize: 24,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Text(
                            _isPaused ? "PAUSED" : "RIDING",
                            style: GoogleFonts.bebasNeue(
                              color: _isPaused ? Colors.orange : theme.primary,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Riding",
                                style: TextStyle(
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.65,
                                  ),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                format(ridingDuration),
                                style: GoogleFonts.bebasNeue(
                                  color: _isPaused
                                      ? Colors.orange
                                      : theme.textPrimary,
                                  fontSize: 18,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Journey",
                                style: TextStyle(
                                  color: theme.textPrimary.withValues(
                                    alpha: 0.65,
                                  ),
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                format(journeyDuration),
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
                    ],
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
                          allReached
                              ? "FINISHED"
                              : "#$currentIndex/$totalCheckpoints",
                          style: TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _checkpointLabel(
                          currentIndex,
                          totalCheckpoints,
                          theme,
                          allReached,
                        ),
                        if (_isPaused) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              "PAUSED",
                              style: GoogleFonts.bebasNeue(
                                color: Colors.orange,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
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
                            "Distance to $checkpointLabelText: $remainingDistanceLabel",
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
                                    : (_isPaused
                                          ? theme.surface
                                          : theme.primary),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  if (!_loading && !_isPaused)
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
                                      : (_isPaused
                                            ? "Resume to Continue"
                                            : "Hold to Mark Reached"),
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
                    ] else if (allReached) ...[
                      if (_canManageRide)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _endRide(theme),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "END RIDE",
                              style: GoogleFonts.bebasNeue(
                                color: Colors.white,
                                fontSize: 18,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "Destination Reached! Waiting for Captain to end ride.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addCustomCheckpoint(theme),
                            icon: const Icon(
                              Icons.add_location_alt_outlined,
                              size: 18,
                            ),
                            label: Text(
                              "MARK POINT",
                              style: GoogleFonts.bebasNeue(letterSpacing: 1.1),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.primary,
                              side: BorderSide(
                                color: theme.primary.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              setState(() {
                                _isPaused = !_isPaused;
                                if (_isPaused) {
                                  _pauseStartTime = DateTime.now();
                                } else if (_pauseStartTime != null) {
                                  _totalPausedTime += DateTime.now().difference(
                                    _pauseStartTime!,
                                  );
                                  _pauseStartTime = null;
                                }
                              });
                              await _persistPauseState();
                            },
                            icon: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              size: 18,
                            ),
                            label: Text(
                              _isPaused ? "RESUME" : "PAUSE RIDE",
                              style: GoogleFonts.bebasNeue(letterSpacing: 1.1),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isPaused
                                  ? Colors.green
                                  : Colors.orange,
                              side: BorderSide(
                                color:
                                    (_isPaused ? Colors.green : Colors.orange)
                                        .withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _checkpointLabel(
    int index,
    int total,
    AppThemeConfig theme,
    bool allReached,
  ) {
    String label = "CHECKPOINT";
    Color color = theme.primary;

    if (allReached) {
      label = "RIDE COMPLETED";
      color = Colors.green;
    } else if (index == 1) {
      label = "START POINT";
      color = Colors.blue;
    } else if (index == total) {
      label = "DESTINATION";
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.bebasNeue(
          color: color,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "");
  }

  int _nearestRouteIndex(latlng.LatLng point) {
    if (_roadRoutePoints.isEmpty) {
      return -1;
    }
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _roadRoutePoints.length; i++) {
      final currentDistance = _distance(point, _roadRoutePoints[i]);
      if (currentDistance < bestDistance) {
        bestDistance = currentDistance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<latlng.LatLng> _completedRoutePoints() {
    final currentLocation = _currentLocation;
    if (_roadRoutePoints.length < 2 || currentLocation == null) {
      return const <latlng.LatLng>[];
    }

    final nearestIndex = _nearestRouteIndex(currentLocation);
    if (nearestIndex <= 0) {
      return const <latlng.LatLng>[];
    }

    if (_distance(currentLocation, _roadRoutePoints[nearestIndex]) >
        _routeSnapThresholdMeters) {
      return const <latlng.LatLng>[];
    }

    return <latlng.LatLng>[
      ..._roadRoutePoints.take(nearestIndex),
      currentLocation,
    ];
  }

  List<latlng.LatLng> _upcomingRoutePoints() {
    if (_roadRoutePoints.length < 2) {
      return const <latlng.LatLng>[];
    }

    final currentLocation = _currentLocation;
    if (currentLocation == null) {
      return _roadRoutePoints;
    }

    final nearestIndex = _nearestRouteIndex(currentLocation);
    if (nearestIndex < 0) {
      return _roadRoutePoints;
    }

    if (_distance(currentLocation, _roadRoutePoints[nearestIndex]) >
        _routeSnapThresholdMeters) {
      return _roadRoutePoints;
    }

    return <latlng.LatLng>[
      currentLocation,
      ..._roadRoutePoints.skip(nearestIndex),
    ];
  }

  double _remainingDistanceMeters() {
    final currentLocation = _currentLocation;
    if (currentLocation == null || _roadRoutePoints.length < 2) {
      return _routeDistanceMeters;
    }

    final nearestIndex = _nearestRouteIndex(currentLocation);
    if (nearestIndex < 0) {
      return _routeDistanceMeters;
    }

    var remaining = _distance(currentLocation, _roadRoutePoints[nearestIndex]);
    for (var i = nearestIndex; i < _roadRoutePoints.length - 1; i++) {
      remaining += _distance(_roadRoutePoints[i], _roadRoutePoints[i + 1]);
    }
    return remaining;
  }

  RoadRouteStep? _nextStep() {
    final currentLocation = _currentLocation;
    if (_routeSteps.isEmpty) {
      return null;
    }
    if (currentLocation == null || _roadRoutePoints.isEmpty) {
      return _routeSteps.first;
    }

    final currentRouteIndex = _nearestRouteIndex(currentLocation);
    RoadRouteStep? fallback;
    for (final step in _routeSteps) {
      final stepPoint = latlng.LatLng(
        step.maneuverPoint.latitude,
        step.maneuverPoint.longitude,
      );
      final stepDistance = _distance(currentLocation, stepPoint);
      if (stepDistance <= 25) {
        continue;
      }
      final stepRouteIndex = _nearestRouteIndex(stepPoint);
      if (stepRouteIndex >= currentRouteIndex) {
        return step;
      }
      fallback ??= step;
    }
    return fallback;
  }

  String _formatDistance(double meters) {
    if (meters <= 0) {
      return "0 m";
    }
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1)} km";
    }
    return "${meters.round()} m";
  }

  String _formatSpeed(double speedMps) {
    final speedKph = speedMps * 3.6;
    if (speedKph.isNaN || speedKph.isInfinite || speedKph < 0) {
      return "0 km/h";
    }
    return "${speedKph.round()} km/h";
  }

  String _etaText(double remainingMeters) {
    if (_routeDistanceMeters <= 0 || _routeDurationSeconds <= 0) {
      return "--";
    }
    final secondsPerMeter = _routeDurationSeconds / _routeDistanceMeters;
    final remainingSeconds = (remainingMeters * secondsPerMeter).round();
    final eta = Duration(seconds: remainingSeconds);
    if (eta.inHours > 0) {
      return "${eta.inHours}h ${eta.inMinutes % 60}m";
    }
    return "${eta.inMinutes}m";
  }

  IconData _stepIcon(RoadRouteStep? step) {
    final modifier = (step?.maneuverModifier ?? "").toLowerCase();
    final type = (step?.maneuverType ?? "").toLowerCase();

    if (type == "roundabout" || type == "rotary") {
      return Icons.roundabout_right;
    }
    if (modifier.contains("left")) {
      return Icons.turn_left;
    }
    if (modifier.contains("right")) {
      return Icons.turn_right;
    }
    if (modifier == "straight") {
      return Icons.straight;
    }
    if (modifier == "uturn") {
      return Icons.u_turn_left;
    }
    return Icons.navigation;
  }

  Marker? _buildCurrentLocationMarker(AppThemeConfig theme) {
    final currentLocation = _currentLocation;
    if (currentLocation == null) {
      return null;
    }

    return Marker(
      point: currentLocation,
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: (_currentHeading * math.pi) / 180,
              child: Icon(Icons.navigation, color: theme.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }

  Widget _speedPill(String speed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        speed,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _navMetric(
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
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveRideMap(
    AppThemeConfig theme, {
    required List<Map<String, dynamic>> participants,
    required List<Map<String, dynamic>> checkpoints,
    required int ridersWithLocation,
  }) {
    final checkpointPoints = <latlng.LatLng>[];
    final markers = <Marker>[];
    final currentUserUuid = (_session?["currentUserUuid"] ?? "").toString();
    final currentLocationMarker = _buildCurrentLocationMarker(theme);
    final currentLocationMarkers = currentLocationMarker == null
        ? const <Marker>[]
        : <Marker>[currentLocationMarker];
    final currentLocationPoints = _currentLocation == null
        ? const <latlng.LatLng>[]
        : <latlng.LatLng>[_currentLocation!];

    for (final checkpoint in checkpoints) {
      final latitude = _toDouble(checkpoint["latitude"]);
      final longitude = _toDouble(checkpoint["longitude"]);
      if (latitude == null || longitude == null) {
        continue;
      }

      final point = latlng.LatLng(latitude, longitude);
      checkpointPoints.add(point);
      final status = (checkpoint["checkpointStatus"] ?? "")
          .toString()
          .toUpperCase();
      final title = (checkpoint["title"] ?? "Checkpoint").toString();
      final color = switch (status) {
        "CURRENT" => theme.primary,
        "REACHED" => Colors.green,
        _ => Colors.redAccent,
      };

      markers.add(
        Marker(
          point: point,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Tooltip(
              message: title,
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    for (final participant in participants) {
      final latitude = _toDouble(participant["lastLatitude"]);
      final longitude = _toDouble(participant["lastLongitude"]);
      if (latitude == null || longitude == null) {
        continue;
      }

      final name =
          (participant["username"] ??
                  participant["firstName"] ??
                  participant["riderId"] ??
                  "Rider")
              .toString();
      final isCurrentUser =
          (participant["userUuid"] ?? "").toString() == currentUserUuid;

      if (isCurrentUser && _currentLocation != null) {
        continue;
      }

      markers.add(
        Marker(
          point: latlng.LatLng(latitude, longitude),
          width: 42,
          height: 42,
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentUser ? theme.primary : const Color(0xFF18202D),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Tooltip(
              message: isCurrentUser ? "You" : name,
              child: Icon(
                isCurrentUser ? Icons.navigation : Icons.two_wheeler,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }

    final initialPoints = <latlng.LatLng>[
      ...checkpointPoints,
      ..._roadRoutePoints,
      ...currentLocationPoints,
      ...markers.map((marker) => marker.point),
    ];

    if (initialPoints.isEmpty) {
      return Center(
        child: Text(
          "Map Preview\n$ridersWithLocation rider locations synced",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xff8C95A8)),
        ),
      );
    }

    final nextStep = _nextStep();
    final nextStepDistance = _currentLocation != null && nextStep != null
        ? _distance(
            _currentLocation!,
            latlng.LatLng(
              nextStep.maneuverPoint.latitude,
              nextStep.maneuverPoint.longitude,
            ),
          )
        : 0.0;
    final completedRoute = _completedRoutePoints();
    final upcomingRoute = _upcomingRoutePoints();
    final remainingDistance = _remainingDistanceMeters();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialPoints.first,
            initialZoom: _cameraZoom,
            onPositionChanged: (camera, hasGesture) {
              if (!hasGesture) {
                return;
              }
              if (_isFollowingUser) {
                setState(() {
                  _isFollowingUser = false;
                });
              }
            },
            initialCameraFit: initialPoints.length > 1
                ? CameraFit.coordinates(
                    coordinates: initialPoints,
                    padding: const EdgeInsets.all(36),
                    maxZoom: 14.5,
                  )
                : null,
          ),
          children: [
            TileLayer(
              urlTemplate: _hasMapboxToken
                  ? _mapboxTileUrl
                  : "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "com.ridersclub.throttle_ui",
            ),
            if (completedRoute.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: completedRoute,
                    strokeWidth: 6,
                    color: Colors.white.withValues(alpha: 0.32),
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
            if (!_routeUnavailable && upcomingRoute.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: upcomingRoute,
                    strokeWidth: 6,
                    color: theme.primary,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
            MarkerLayer(markers: [...markers, ...currentLocationMarkers]),
            const RichAttributionWidget(
              popupInitialDisplayDuration: Duration.zero,
              attributions: [
                TextSourceAttribution("© Mapbox"),
                TextSourceAttribution("© OpenStreetMap"),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _stepIcon(nextStep),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextStep?.instruction ??
                            (_routeLoading
                                ? "Building navigation route"
                                : "Follow the highlighted route"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextStep != null
                            ? "In ${_formatDistance(nextStepDistance)}"
                            : (_routeUnavailable
                                  ? "Road routing unavailable right now"
                                  : "Navigation starts automatically as your ride location updates"),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 112,
          child: Column(
            children: [
              _mapActionButton(
                icon: _isVoiceMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                onTap: () {
                  setState(() {
                    _isVoiceMuted = !_isVoiceMuted;
                  });
                },
              ),
              const SizedBox(height: 10),
              _mapActionButton(icon: Icons.layers_outlined, onTap: () {}),
              if (!_isFollowingUser && _currentLocation != null) ...[
                const SizedBox(height: 10),
                _mapActionButton(
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    setState(() {
                      _isFollowingUser = true;
                    });
                    _animateCameraTo(_currentLocation!, zoom: _navigationZoom);
                  },
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 12,
          bottom: 86,
          child: _speedPill(_formatSpeed(_currentSpeedMps)),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navMetric(
                  theme,
                  label: "Remaining",
                  value: _formatDistance(remainingDistance),
                ),
                _navMetric(
                  theme,
                  label: "ETA",
                  value: _etaText(remainingDistance),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  latlng.LatLng? _currentUserLocation(
    List<Map<String, dynamic>> participants,
    String currentUserUuid,
  ) {
    for (final participant in participants) {
      if ((participant["userUuid"] ?? "").toString() != currentUserUuid) {
        continue;
      }
      final latitude = _toDouble(participant["lastLatitude"]);
      final longitude = _toDouble(participant["lastLongitude"]);
      if (latitude != null && longitude != null) {
        return latlng.LatLng(latitude, longitude);
      }
    }
    return null;
  }

  String _remainingDistanceLabel(
    Map<String, dynamic> currentCheckpoint,
    latlng.LatLng? currentUserLocation,
  ) {
    if (_roadRoutePoints.length > 1 && _routeDistanceMeters > 0) {
      return _formatDistance(_remainingDistanceMeters());
    }
    if (currentCheckpoint.isEmpty || currentUserLocation == null) {
      return "Locating rider...";
    }

    final checkpointLat = _toDouble(currentCheckpoint["latitude"]);
    final checkpointLng = _toDouble(currentCheckpoint["longitude"]);
    if (checkpointLat == null || checkpointLng == null) {
      return "Unavailable";
    }

    final meters = _distance(
      currentUserLocation,
      latlng.LatLng(checkpointLat, checkpointLng),
    );

    return _formatDistance(meters);
  }
}
