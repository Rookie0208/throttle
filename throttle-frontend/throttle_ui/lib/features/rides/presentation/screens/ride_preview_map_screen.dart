import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:throttle_ui/core/services/location_service.dart';
import 'package:throttle_ui/core/services/routing_service.dart';

class RidePreviewPoint {
  final String title;
  final double latitude;
  final double longitude;
  final String kind;

  const RidePreviewPoint({
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.kind,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

class RidePreviewMapScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<RidePreviewPoint> points;

  const RidePreviewMapScreen({
    super.key,
    required this.title,
    required this.points,
    this.subtitle,
  });

  @override
  State<RidePreviewMapScreen> createState() => _RidePreviewMapScreenState();
}

class _RidePreviewMapScreenState extends State<RidePreviewMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  static const LatLng _fallbackCenter = LatLng(20.5937, 78.9629);
  static const double _followZoom = 16.6;
  static const double _routeSnapThresholdMeters = 80;

  List<LatLng> _roadRoute = const <LatLng>[];
  List<RoadRouteStep> _routeSteps = const <RoadRouteStep>[];
  double _routeDistanceMeters = 0;
  double _routeDurationSeconds = 0;
  bool _routeLoading = true;
  bool _routeUnavailable = false;

  LatLng? _currentLocation;
  double _currentSpeedMps = 0;
  double _currentHeading = 0;
  bool _isFollowingUser = true;
  bool _isVoiceMuted = false;
  StreamSubscription<Position>? _positionSubscription;
  AnimationController? _cameraAnimationController;

  LatLng _cameraCenter = _fallbackCenter;
  double _cameraZoom = 13;

  String get _mapboxPublicToken =>
      dotenv.env['MAPBOX_PUBLIC_TOKEN']?.trim() ?? '';

  String get _mapboxTileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxPublicToken';

  bool get _hasMapboxToken => _mapboxPublicToken.isNotEmpty;

  List<RidePreviewPoint> get _routePoints {
    final primaryPoints = widget.points
        .where((point) => point.kind != 'meeting')
        .toList();
    if (primaryPoints.length >= 2) {
      return primaryPoints;
    }
    return widget.points;
  }

  @override
  void initState() {
    super.initState();
    _cameraCenter = widget.points.isNotEmpty
        ? widget.points.first.latLng
        : _fallbackCenter;
    _cameraZoom = _routePoints.length > 1 ? 10.5 : 13;
    _loadRoadRoute();
    _startNavigationTracking();
  }

  @override
  void dispose() {
    _cameraAnimationController?.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRoadRoute() async {
    if (_routePoints.length < 2) {
      if (!mounted) {
        return;
      }
      setState(() {
        _roadRoute = _routePoints.map((point) => point.latLng).toList();
        _routeSteps = const <RoadRouteStep>[];
        _routeDistanceMeters = 0;
        _routeDurationSeconds = 0;
        _routeLoading = false;
        _routeUnavailable = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _routeLoading = true;
      });
    }

    final result = await RoutingService.fetchRoadRouteDetails(
      _routePoints.map((point) => point.latLng).toList(),
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _roadRoute = result.points;
      _routeSteps = result.steps;
      _routeDistanceMeters = result.distanceMeters;
      _routeDurationSeconds = result.durationSeconds;
      _routeLoading = false;
      _routeUnavailable = result.isFallback;
    });
  }

  Future<void> _startNavigationTracking() async {
    final initialPosition = await LocationService.getCurrentLocation();
    if (!mounted) {
      return;
    }

    if (initialPosition != null) {
      _applyPosition(initialPosition, animateCamera: true);
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
          _applyPosition(position, animateCamera: true);
        });
  }

  void _applyPosition(Position position, {required bool animateCamera}) {
    final nextLocation = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentLocation = nextLocation;
      _currentSpeedMps = position.speed >= 0 ? position.speed : 0;
      _currentHeading = _normalizedHeading(position.heading);
    });

    if (animateCamera && _isFollowingUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _animateCameraTo(nextLocation, zoom: _followZoom);
      });
    }
  }

  void _animateCameraTo(LatLng target, {required double zoom}) {
    _cameraAnimationController?.stop();
    _cameraAnimationController?.dispose();

    final startCenter = _cameraCenter;
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
      final center = LatLng(
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

  int _nearestRouteIndex(LatLng point) {
    if (_roadRoute.isEmpty) {
      return -1;
    }
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _roadRoute.length; i++) {
      final distance = _distance(point, _roadRoute[i]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<LatLng> _upcomingRoutePoints() {
    if (_roadRoute.length < 2) {
      return const <LatLng>[];
    }

    final currentLocation = _currentLocation;
    if (currentLocation == null) {
      return _roadRoute;
    }

    final nearestIndex = _nearestRouteIndex(currentLocation);
    if (nearestIndex < 0) {
      return _roadRoute;
    }

    final snappedPoint = _roadRoute[nearestIndex];
    final isNearRoute =
        _distance(currentLocation, snappedPoint) <= _routeSnapThresholdMeters;
    if (!isNearRoute) {
      return _roadRoute;
    }

    return <LatLng>[currentLocation, ..._roadRoute.skip(nearestIndex)];
  }

  List<LatLng> _completedRoutePoints() {
    if (_roadRoute.length < 2 || _currentLocation == null) {
      return const <LatLng>[];
    }

    final nearestIndex = _nearestRouteIndex(_currentLocation!);
    if (nearestIndex <= 0) {
      return const <LatLng>[];
    }

    if (_distance(_currentLocation!, _roadRoute[nearestIndex]) >
        _routeSnapThresholdMeters) {
      return const <LatLng>[];
    }

    return <LatLng>[..._roadRoute.take(nearestIndex), _currentLocation!];
  }

  double _remainingDistanceMeters() {
    final currentLocation = _currentLocation;
    if (currentLocation == null || _roadRoute.length < 2) {
      return _routeDistanceMeters;
    }

    final nearestIndex = _nearestRouteIndex(currentLocation);
    if (nearestIndex < 0) {
      return _routeDistanceMeters;
    }

    var remaining = _distance(currentLocation, _roadRoute[nearestIndex]);
    for (var i = nearestIndex; i < _roadRoute.length - 1; i++) {
      remaining += _distance(_roadRoute[i], _roadRoute[i + 1]);
    }
    return remaining;
  }

  RoadRouteStep? _nextStep() {
    final currentLocation = _currentLocation;
    if (_routeSteps.isEmpty) {
      return null;
    }
    if (currentLocation == null || _roadRoute.isEmpty) {
      return _routeSteps.first;
    }

    final currentRouteIndex = _nearestRouteIndex(currentLocation);
    RoadRouteStep? fallback;

    for (final step in _routeSteps) {
      final stepDistance = _distance(currentLocation, step.maneuverPoint);
      if (stepDistance <= 25) {
        continue;
      }
      final stepRouteIndex = _nearestRouteIndex(step.maneuverPoint);
      if (stepRouteIndex >= currentRouteIndex) {
        return step;
      }
      fallback ??= step;
    }

    return fallback;
  }

  String _formatDistance(double meters) {
    if (meters <= 0) {
      return '0 m';
    }
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatSpeed(double speedMps) {
    final speedKph = speedMps * 3.6;
    if (speedKph.isNaN || speedKph.isInfinite || speedKph < 0) {
      return '0 km/h';
    }
    return '${speedKph.round()} km/h';
  }

  String _etaText(double remainingMeters) {
    if (_routeDistanceMeters <= 0 || _routeDurationSeconds <= 0) {
      return '--';
    }
    final secondsPerMeter = _routeDurationSeconds / _routeDistanceMeters;
    final remainingSeconds = (remainingMeters * secondsPerMeter).round();
    final eta = Duration(seconds: remainingSeconds);
    if (eta.inHours > 0) {
      return '${eta.inHours}h ${eta.inMinutes % 60}m';
    }
    return '${eta.inMinutes}m';
  }

  IconData _stepIcon(RoadRouteStep? step) {
    final modifier = (step?.maneuverModifier ?? '').toLowerCase();
    final type = (step?.maneuverType ?? '').toLowerCase();

    if (type == 'roundabout' || type == 'rotary') {
      return Icons.roundabout_right;
    }
    if (modifier.contains('left')) {
      return Icons.turn_left;
    }
    if (modifier.contains('right')) {
      return Icons.turn_right;
    }
    if (modifier == 'straight') {
      return Icons.straight;
    }
    if (modifier == 'uturn') {
      return Icons.u_turn_left;
    }
    return Icons.navigation;
  }

  Marker? _buildCurrentLocationMarker() {
    final currentLocation = _currentLocation;
    if (currentLocation == null) {
      return null;
    }

    return Marker(
      point: currentLocation,
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: (_currentHeading * math.pi) / 180,
              child: const Icon(Icons.navigation, color: Colors.blue, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String kind, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (kind) {
      'start' => scheme.primary,
      'end' => Colors.redAccent,
      'checkpoint' => Colors.amber.shade700,
      'meeting' => Colors.teal,
      _ => scheme.primary,
    };
  }

  IconData _iconFor(String kind) {
    return switch (kind) {
      'start' => Icons.trip_origin,
      'end' => Icons.flag_rounded,
      'checkpoint' => Icons.location_on,
      'meeting' => Icons.people_alt_rounded,
      _ => Icons.place,
    };
  }

  String _labelFor(String kind) {
    return switch (kind) {
      'start' => 'Start',
      'end' => 'Destination',
      'checkpoint' => 'Checkpoint',
      'meeting' => 'Meeting Point',
      _ => 'Location',
    };
  }

  Marker _buildMarker(BuildContext context, RidePreviewPoint point) {
    final color = _colorFor(point.kind, context);
    return Marker(
      point: point.latLng,
      width: 54,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(_iconFor(point.kind), color: Colors.white, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeCoordinates = _routePoints.map((point) => point.latLng).toList();
    final fitCoordinates = _roadRoute.length > 1
        ? _roadRoute
        : routeCoordinates;
    final initialCenter = widget.points.isNotEmpty
        ? widget.points.first.latLng
        : _fallbackCenter;
    final currentLocationMarker = _buildCurrentLocationMarker();
    final currentLocationMarkers = currentLocationMarker == null
        ? const <Marker>[]
        : <Marker>[currentLocationMarker];
    final completedRoute = _completedRoutePoints();
    final upcomingRoute = _upcomingRoutePoints();
    final remainingDistanceMeters = _remainingDistanceMeters();
    final nextStep = _nextStep();
    final nextStepDistance = _currentLocation != null && nextStep != null
        ? _distance(_currentLocation!, nextStep.maneuverPoint)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (widget.subtitle != null && widget.subtitle!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                widget.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: !_hasMapboxToken
                  ? const Center(
                      child: Text(
                        'Mapbox public token is missing. Add it to .env to view the map.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : widget.points.isEmpty
                  ? const Center(
                      child: Text(
                        'No exact ride locations are available yet.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: initialCenter,
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
                              initialCameraFit: fitCoordinates.length > 1
                                  ? CameraFit.coordinates(
                                      coordinates: fitCoordinates,
                                      padding: const EdgeInsets.all(42),
                                      maxZoom: 13.8,
                                    )
                                  : null,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: _mapboxTileUrl,
                                userAgentPackageName:
                                    'com.ridersclub.throttle_ui',
                              ),
                              if (completedRoute.length > 1)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: completedRoute,
                                      strokeWidth: 6,
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      strokeCap: StrokeCap.round,
                                      strokeJoin: StrokeJoin.round,
                                    ),
                                  ],
                                ),
                              if (!_routeUnavailable &&
                                  upcomingRoute.length > 1)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: upcomingRoute,
                                      strokeWidth: 6,
                                      color: theme.colorScheme.primary,
                                      strokeCap: StrokeCap.round,
                                      strokeJoin: StrokeJoin.round,
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  ...widget.points.map(
                                    (point) => _buildMarker(context, point),
                                  ),
                                  ...currentLocationMarkers,
                                ],
                              ),
                              const RichAttributionWidget(
                                popupInitialDisplayDuration: Duration.zero,
                                attributions: [
                                  TextSourceAttribution('© Mapbox'),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nextStep?.instruction ??
                                              (_routeLoading
                                                  ? 'Building navigation route'
                                                  : 'Follow the highlighted route'),
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          nextStep != null
                                              ? 'In ${_formatDistance(nextStepDistance)}'
                                              : (_routeUnavailable
                                                    ? 'Road routing unavailable right now'
                                                    : 'Live guidance will begin when your location is available'),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.86,
                                                ),
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
                            right: 14,
                            bottom: 116,
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
                                _mapActionButton(
                                  icon: Icons.layers_outlined,
                                  onTap: () {},
                                ),
                                if (!_isFollowingUser &&
                                    _currentLocation != null) ...[
                                  const SizedBox(height: 10),
                                  _mapActionButton(
                                    icon: Icons.my_location_rounded,
                                    onTap: () {
                                      setState(() {
                                        _isFollowingUser = true;
                                      });
                                      _animateCameraTo(
                                        _currentLocation!,
                                        zoom: _followZoom,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Positioned(
                            left: 14,
                            bottom: 86,
                            child: _bottomPill(
                              label: _formatSpeed(_currentSpeedMps),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.76),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _metric(
                                    context,
                                    label: 'Remaining',
                                    value: _formatDistance(
                                      remainingDistanceMeters,
                                    ),
                                  ),
                                  _metric(
                                    context,
                                    label: 'ETA',
                                    value: _etaText(remainingDistanceMeters),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (widget.points.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.points
                    .map(
                      (point) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconFor(point.kind),
                              size: 16,
                              color: _colorFor(point.kind, context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_labelFor(point.kind)}: ${point.title}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomPill({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
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

  Widget _metric(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
