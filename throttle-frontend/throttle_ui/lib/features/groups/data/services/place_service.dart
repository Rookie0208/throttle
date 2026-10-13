import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class PlaceService {
  static const int _maxResults = 5;

  static Future<List<Map<String, String>>> searchPlaces(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 3) return const [];

    final uri = Uri.https("photon.komoot.io", "/api/", {
      "q": trimmedQuery,
      "limit": "$_maxResults",
      "lang": "en",
      "countrycode": "IN",
    });

    final response = await http.get(
      uri,
      headers: {
        "Accept": "application/geo+json, application/json",
        if (!kIsWeb) "User-Agent": "Throttle/1.0",
      },
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Location search is unavailable right now (Status: ${response.statusCode})",
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const [];
    final features = decoded["features"];
    if (features is! List) return const [];

    return features
        .whereType<Map>()
        .map((feature) => Map<String, dynamic>.from(feature))
        .map((feature) {
          final properties = feature["properties"] is Map
              ? Map<String, dynamic>.from(feature["properties"] as Map)
              : <String, dynamic>{};
          final geometry = feature["geometry"] is Map
              ? Map<String, dynamic>.from(feature["geometry"] as Map)
              : <String, dynamic>{};
          final coordinates = geometry["coordinates"];
          final title = properties["name"]?.toString().trim() ?? "";
          final displayName = _displayName(properties, title);
          final latitude = coordinates is List && coordinates.length >= 2
              ? coordinates[1].toString()
              : "";
          final longitude = coordinates is List && coordinates.length >= 2
              ? coordinates[0].toString()
              : "";
          final displayTitle = title.isEmpty ? displayName : title;

          return <String, String>{
            "placeId": properties["osm_id"]?.toString() ?? "",
            "title": displayTitle,
            "subtitle": displayName == displayTitle
                ? ""
                : displayName
                    .substring(displayTitle.length)
                    .replaceFirst(RegExp(r"^[,\s]+"), ""),
            "fullText": displayName,
            "latitude": latitude,
            "longitude": longitude,
          };
        })
        .where(
          (item) =>
              item["fullText"]?.isNotEmpty == true &&
              item["latitude"]?.isNotEmpty == true &&
              item["longitude"]?.isNotEmpty == true,
        )
        .toList();
  }

  static String _displayName(Map<String, dynamic> properties, String title) {
    final street = [
      properties["housenumber"],
      properties["street"],
    ]
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .join(" ");
    final parts = <String>[
      title,
      if (street.isNotEmpty) street,
      properties["district"]?.toString() ?? "",
      properties["city"]?.toString() ?? "",
      properties["state"]?.toString() ?? "",
      properties["country"]?.toString() ?? "",
    ];
    final uniqueParts = <String>[];
    for (final part in parts) {
      final value = part.trim();
      if (value.isNotEmpty &&
          !uniqueParts.any(
            (existing) => existing.toLowerCase() == value.toLowerCase(),
          )) {
        uniqueParts.add(value);
      }
    }
    return uniqueParts.join(", ");
  }
}
