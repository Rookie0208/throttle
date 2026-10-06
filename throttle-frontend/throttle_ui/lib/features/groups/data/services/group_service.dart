import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:throttle_ui/core/constants/app_constants.dart';
import 'package:throttle_ui/core/network/auth_headers.dart';

class GroupService {
  static String get baseUrl => AppConstants.baseUrl;

  static Future<Map<String, String>> _headers(String token) =>
      AuthHeaders.json(token);

  static Future<void> updateRide(
    String token,
    String rideUuid,
    Map payload,
  ) async {
    await http.put(
      Uri.parse("$baseUrl/rides/$rideUuid"),
      headers: await _headers(token),
      body: jsonEncode(payload),
    );
  }

  static Future<Map<String, dynamic>> updatePreRideInfo(
    String token,
    String groupId,
    Map<String, dynamic> preRideInfo,
  ) async {
    final url = Uri.parse('$baseUrl/rides/groups/$groupId/pre-ride-info');
    final response = await http.put(
      url,
      headers: await _headers(token),
      body: json.encode(preRideInfo),
    );

    final decoded = json.decode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(decoded['data'] ?? const {});
    }
    throw Exception(decoded['message'] ?? 'Failed to update pre-ride info');
  }

  static Future<Map<String, dynamic>> fetchPreRideInfo(
    String token,
    String groupId,
  ) async {
    final url = Uri.parse('$baseUrl/rides/groups/$groupId/pre-ride-info');
    final response = await http.get(
      url,
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return Map<String, dynamic>.from(decoded['data'] ?? const {});
    }
    final decoded = json.decode(response.body);
    throw Exception(decoded['message'] ?? 'Failed to load pre-ride info');
  }

  static Future<Map<String, dynamic>> fetchMyGroups(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rides/my"),
        headers: await _headers(token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"success": true, "data": data["data"]};
      } else {
        return {"success": false, "message": data["message"]};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> fetchRideMembers(
    String token,
    String rideUuid,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/participants/$rideUuid"),
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch ride members");
    }
  }

  /// ================= JOIN RIDE =================
  static Future<void> joinRide(String token, String rideId) async {
    final url = Uri.parse("$baseUrl/rides/$rideId/join");

    final response = await http.post(
      url,
      headers: await _headers(token),
    );

    final Map<String, dynamic> data = response.body.isEmpty
        ? const {}
        : Map<String, dynamic>.from(jsonDecode(response.body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data["success"] == false) {
        throw Exception(data["message"] ?? "Failed to join ride");
      }

      return; // success
    } else {
      throw Exception(
        data["message"] ?? "Failed to join ride: ${response.statusCode}",
      );
    }
  }

  /// ================= FETCH PUBLIC RIDES =================
  static Future<Map<String, dynamic>> fetchPublicRides(String token) async {
    final url = Uri.parse("$baseUrl/rides/public");

    final response = await http.get(
      url,
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data == null || data["data"] == null) {
        return {"data": []};
      }

      return data;
    } else {
      throw Exception("Failed to fetch public rides: ${response.statusCode}");
    }
  }
}
