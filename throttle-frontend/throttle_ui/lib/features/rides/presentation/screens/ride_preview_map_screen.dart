import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

class RidePreviewMapScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<RidePreviewPoint> points;

  const RidePreviewMapScreen({
    super.key,
    required this.title,
    required this.points,
    this.subtitle,
  });

  static const LatLng _fallbackCenter = LatLng(20.5937, 78.9629);

  String get _mapboxPublicToken =>
      dotenv.env["MAPBOX_PUBLIC_TOKEN"]?.trim() ?? "";

  String get _mapboxTileUrl =>
      "https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxPublicToken";

  bool get _hasMapboxToken => _mapboxPublicToken.isNotEmpty;

  List<RidePreviewPoint> get _routePoints =>
      points.where((point) => point.kind != "meeting").toList();

  Color _colorFor(String kind, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (kind) {
      "start" => scheme.primary,
      "end" => Colors.redAccent,
      "checkpoint" => Colors.amber.shade700,
      "meeting" => Colors.teal,
      _ => scheme.primary,
    };
  }

  IconData _iconFor(String kind) {
    return switch (kind) {
      "start" => Icons.trip_origin,
      "end" => Icons.flag_rounded,
      "checkpoint" => Icons.location_on,
      "meeting" => Icons.people_alt_rounded,
      _ => Icons.place,
    };
  }

  String _labelFor(String kind) {
    return switch (kind) {
      "start" => "Start",
      "end" => "Destination",
      "checkpoint" => "Checkpoint",
      "meeting" => "Meeting Point",
      _ => "Location",
    };
  }

  Marker _buildMarker(BuildContext context, RidePreviewPoint point) {
    final color = _colorFor(point.kind, context);
    return Marker(
      point: point.latLng,
      width: 50,
      height: 50,
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
    final initialCenter = points.isNotEmpty
        ? points.first.latLng
        : _fallbackCenter;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          if (subtitle != null && subtitle!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                subtitle!,
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
                        "Mapbox public token is missing. Add it to .env to view the map.",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : points.isEmpty
                  ? const Center(
                      child: Text(
                        "No exact ride locations are available yet.",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: initialCenter,
                          initialZoom: routeCoordinates.length > 1 ? 10.5 : 13,
                          initialCameraFit: routeCoordinates.length > 1
                              ? CameraFit.coordinates(
                                  coordinates: routeCoordinates,
                                  padding: const EdgeInsets.all(40),
                                  maxZoom: 13.5,
                                )
                              : null,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: _mapboxTileUrl,
                            userAgentPackageName: "com.ridersclub.throttle_ui",
                          ),
                          if (routeCoordinates.length > 1)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routeCoordinates,
                                  strokeWidth: 5,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: points
                                .map((point) => _buildMarker(context, point))
                                .toList(),
                          ),
                          const RichAttributionWidget(
                            popupInitialDisplayDuration: Duration.zero,
                            attributions: [TextSourceAttribution("© Mapbox")],
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (points.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: points
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
                              "${_labelFor(point.kind)}: ${point.title}",
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
}
