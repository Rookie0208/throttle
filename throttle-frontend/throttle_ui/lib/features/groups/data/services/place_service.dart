import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceService {
  static const int _maxResults = 5;

  static Future<List<Map<String, String>>> searchPlaces(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 3) return const [];

    final uri = Uri.https("nominatim.openstreetmap.org", "/search", {
      "q": trimmedQuery,
      "format": "jsonv2",
      "addressdetails": "1",
      "limit": "$_maxResults",
      "countrycodes": "in",
    });

    final response = await http.get(
      uri,
      headers: const {"Accept": "application/json", "Accept-Language": "en"},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Location search is unavailable right now (Status: ${response.statusCode})",
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .map((entry) {
          final displayName = entry["display_name"]?.toString().trim() ?? "";
          final title = _titleFromEntry(entry, displayName);
          final subtitle = _subtitleFromDisplayName(displayName, title);

          return <String, String>{
            "placeId": entry["place_id"]?.toString() ?? "",
            "title": title,
            "subtitle": subtitle,
            "fullText": displayName,
            "latitude": entry["lat"]?.toString() ?? "",
            "longitude": entry["lon"]?.toString() ?? "",
          };
        })
        .where((item) => item["fullText"]?.isNotEmpty == true)
        .toList();
  }

  static String _titleFromEntry(
    Map<String, dynamic> entry,
    String displayName,
  ) {
    final name = entry["name"]?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    if (displayName.isEmpty) return "";

    final separatorIndex = displayName.indexOf(",");
    if (separatorIndex == -1) return displayName;

    return displayName.substring(0, separatorIndex).trim();
  }

  static String _subtitleFromDisplayName(String displayName, String title) {
    if (displayName.isEmpty || title.isEmpty) return "";
    if (displayName == title) return "";

    final prefix = "$title,";
    if (displayName.startsWith(prefix)) {
      return displayName.substring(prefix.length).trim();
    }

    return displayName;
  }
}
