import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoadRouteStep {
  final LatLng maneuverPoint;
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String? roadName;
  final String? maneuverType;
  final String? maneuverModifier;

  const RoadRouteStep({
    required this.maneuverPoint,
    required this.instruction,
    required this.distanceMeters,
    this.durationSeconds = 0,
    this.roadName,
    this.maneuverType,
    this.maneuverModifier,
  });
}

class RoadRouteResult {
  final List<LatLng> points;
  final List<RoadRouteStep> steps;
  final double distanceMeters;
  final double durationSeconds;
  final bool isFallback;
  final String source;

  const RoadRouteResult({
    required this.points,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isFallback = false,
    this.source = 'unknown',
  });

  factory RoadRouteResult.fallback(List<LatLng> waypoints) {
    return RoadRouteResult(
      points: List<LatLng>.from(waypoints),
      steps: const <RoadRouteStep>[],
      distanceMeters: 0,
      durationSeconds: 0,
      isFallback: true,
      source: 'fallback',
    );
  }
}

class RoutingService {
  RoutingService._();

  static Future<List<LatLng>> fetchRoadRoute(List<LatLng> waypoints) async {
    final result = await fetchRoadRouteDetails(waypoints);
    return result.points;
  }

  static Future<RoadRouteResult> fetchRoadRouteDetails(
    List<LatLng> waypoints,
  ) async {
    if (waypoints.isEmpty) {
      return const RoadRouteResult(
        points: <LatLng>[],
        steps: <RoadRouteStep>[],
        distanceMeters: 0,
        durationSeconds: 0,
        source: 'empty',
      );
    }
    if (waypoints.length < 2) {
      return RoadRouteResult.fallback(waypoints);
    }

    try {
      final mapboxResult = await _fetchMapboxRoute(waypoints);
      if (mapboxResult != null) {
        return mapboxResult;
      }

      final osrmResult = await _fetchOsrmRoute(waypoints);
      if (osrmResult != null) {
        return osrmResult;
      }

      return RoadRouteResult.fallback(waypoints);
    } catch (_) {
      return RoadRouteResult.fallback(waypoints);
    }
  }

  static Future<RoadRouteResult?> _fetchMapboxRoute(
    List<LatLng> waypoints,
  ) async {
    final token = dotenv.env['MAPBOX_PUBLIC_TOKEN']?.trim() ?? '';
    if (token.isEmpty) {
      return null;
    }

    final coordinates = waypoints
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    final uri = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/$coordinates'
      '?alternatives=false'
      '&continue_straight=true'
      '&geometries=geojson'
      '&language=en'
      '&overview=full'
      '&steps=true'
      '&access_token=$token',
    );

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return null;
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      return null;
    }

    final route = routes.first;
    if (route is! Map) {
      return null;
    }

    final routePoints = _parseGeoJsonCoordinates(route['geometry']);
    if (routePoints.isEmpty) {
      return null;
    }

    return RoadRouteResult(
      points: routePoints,
      steps: _parseMapboxSteps(route['legs']),
      distanceMeters: _toDouble(route['distance']) ?? 0,
      durationSeconds: _toDouble(route['duration']) ?? 0,
      source: 'mapbox',
    );
  }

  static Future<RoadRouteResult?> _fetchOsrmRoute(
    List<LatLng> waypoints,
  ) async {
    final coordinates = waypoints
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordinates'
      '?overview=full&geometries=geojson&steps=true',
    );

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return null;
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      return null;
    }

    final route = routes.first;
    if (route is! Map) {
      return null;
    }

    final routePoints = _parseGeoJsonCoordinates(route['geometry']);
    if (routePoints.isEmpty) {
      return null;
    }

    return RoadRouteResult(
      points: routePoints,
      steps: _parseOsrmSteps(route['legs']),
      distanceMeters: _toDouble(route['distance']) ?? 0,
      durationSeconds: _toDouble(route['duration']) ?? 0,
      source: 'osrm',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static List<LatLng> _parseGeoJsonCoordinates(dynamic geometryValue) {
    if (geometryValue is! Map) {
      return const <LatLng>[];
    }

    final coordinatesList = geometryValue['coordinates'];
    if (coordinatesList is! List || coordinatesList.isEmpty) {
      return const <LatLng>[];
    }

    final routePoints = <LatLng>[];
    for (final item in coordinatesList) {
      if (item is! List || item.length < 2) {
        continue;
      }
      final lng = _toDouble(item[0]);
      final lat = _toDouble(item[1]);
      if (lat == null || lng == null) {
        continue;
      }
      routePoints.add(LatLng(lat, lng));
    }
    return routePoints;
  }

  static List<RoadRouteStep> _parseMapboxSteps(dynamic legsValue) {
    if (legsValue is! List) {
      return const <RoadRouteStep>[];
    }

    final steps = <RoadRouteStep>[];
    for (final leg in legsValue) {
      if (leg is! Map) {
        continue;
      }
      final legSteps = leg['steps'];
      if (legSteps is! List) {
        continue;
      }
      for (final step in legSteps) {
        if (step is! Map) {
          continue;
        }
        final maneuver = step['maneuver'];
        if (maneuver is! Map) {
          continue;
        }
        final location = maneuver['location'];
        if (location is! List || location.length < 2) {
          continue;
        }
        final lng = _toDouble(location[0]);
        final lat = _toDouble(location[1]);
        if (lat == null || lng == null) {
          continue;
        }

        final instruction = (maneuver['instruction'] ?? '').toString().trim();
        steps.add(
          RoadRouteStep(
            maneuverPoint: LatLng(lat, lng),
            instruction: instruction.isEmpty
                ? _buildInstruction(step, maneuver)
                : instruction,
            distanceMeters: _toDouble(step['distance']) ?? 0,
            durationSeconds: _toDouble(step['duration']) ?? 0,
            roadName: (step['name'] ?? '').toString().trim().isEmpty
                ? null
                : (step['name'] ?? '').toString().trim(),
            maneuverType: (maneuver['type'] ?? '').toString().trim(),
            maneuverModifier: (maneuver['modifier'] ?? '').toString().trim(),
          ),
        );
      }
    }
    return steps;
  }

  static List<RoadRouteStep> _parseOsrmSteps(dynamic legsValue) {
    if (legsValue is! List) {
      return const <RoadRouteStep>[];
    }

    final steps = <RoadRouteStep>[];
    for (final leg in legsValue) {
      if (leg is! Map) {
        continue;
      }
      final legSteps = leg['steps'];
      if (legSteps is! List) {
        continue;
      }
      for (final step in legSteps) {
        if (step is! Map) {
          continue;
        }
        final maneuver = step['maneuver'];
        if (maneuver is! Map) {
          continue;
        }
        final location = maneuver['location'];
        if (location is! List || location.length < 2) {
          continue;
        }
        final lng = _toDouble(location[0]);
        final lat = _toDouble(location[1]);
        if (lat == null || lng == null) {
          continue;
        }

        steps.add(
          RoadRouteStep(
            maneuverPoint: LatLng(lat, lng),
            instruction: _buildInstruction(step, maneuver),
            distanceMeters: _toDouble(step['distance']) ?? 0,
            durationSeconds: _toDouble(step['duration']) ?? 0,
            roadName: (step['name'] ?? '').toString().trim().isEmpty
                ? null
                : (step['name'] ?? '').toString().trim(),
            maneuverType: (maneuver['type'] ?? '').toString().trim(),
            maneuverModifier: (maneuver['modifier'] ?? '').toString().trim(),
          ),
        );
      }
    }
    return steps;
  }

  static String _buildInstruction(Map step, Map maneuver) {
    final modifier = (maneuver['modifier'] ?? '').toString().trim();
    final type = (maneuver['type'] ?? '').toString().trim();
    final roadName = (step['name'] ?? '').toString().trim();

    String base;
    switch (type) {
      case 'depart':
        base = 'Start riding';
        break;
      case 'arrive':
        base = 'Arrive at your destination';
        break;
      case 'roundabout':
      case 'rotary':
        base = 'Take the roundabout';
        break;
      case 'merge':
        base = 'Merge';
        break;
      case 'fork':
        base = 'Keep';
        break;
      case 'end of road':
        base = 'At the end of the road';
        break;
      case 'new name':
      case 'continue':
        base = 'Continue';
        break;
      case 'turn':
      default:
        base = 'Turn';
        break;
    }

    final modifierText = switch (modifier) {
      'left' => 'left',
      'right' => 'right',
      'slight left' => 'slightly left',
      'slight right' => 'slightly right',
      'sharp left' => 'sharply left',
      'sharp right' => 'sharply right',
      'straight' => 'straight',
      'uturn' => 'around',
      _ => '',
    };

    final roadSuffix = roadName.isNotEmpty ? ' onto $roadName' : '';

    if (base == 'Arrive at your destination') {
      return base;
    }
    if (modifierText.isEmpty) {
      return '$base$roadSuffix'.trim();
    }
    return '$base $modifierText$roadSuffix'.trim();
  }
}
