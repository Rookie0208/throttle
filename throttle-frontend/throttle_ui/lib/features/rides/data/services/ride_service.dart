import 'dart:convert';
import 'package:http/http.dart' as http;

class RideService {
  static const String _apiBaseUrl = "http://localhost:8080/api/v1";
  static const List<String> availableRoles = [
    "RIDER",
    "NAVIGATOR",
    "MARSHAL",
    "SWEEPER",
    "CO_CAPTAIN",
    "CAPTAIN",
    "ADMIN",
  ];

  static Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  static Future<Map<String, dynamic>> createRide(
    Map<String, dynamic> rideData,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$_apiBaseUrl/rides/create"),
        headers: _headers(token),
        body: jsonEncode(rideData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Failed to create ride",
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<List<String>> fetchRoles(String token) async {
    final response = await http.get(
      Uri.parse("$_apiBaseUrl/rides/roles"),
      headers: _headers(token),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return List<String>.from(data["data"] ?? availableRoles);
    }

    throw Exception(data["message"] ?? "Failed to fetch ride roles");
  }

  static Future<void> updateUserRole(
    String token,
    String rideUuid,
    String userUuid,
    String role,
  ) async {
    final response = await http.put(
      Uri.parse("$_apiBaseUrl/participants/$rideUuid/$userUuid/role"),
      headers: _headers(token),
      body: jsonEncode({"role": role}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response.body);
      throw Exception(data["message"] ?? "Failed to update role");
    }
  }

  static Future<void> removeMember(
    String token,
    String rideUuid,
    String userUuid,
  ) async {
    final response = await http.delete(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/members/$userUuid"),
      headers: _headers(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response.body);
      throw Exception(data["message"] ?? "Failed to remove rider");
    }
  }

  static Future<void> inviteMember(
    String token,
    String rideUuid,
    String inviteeUuid,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/participants/$rideUuid/invite"),
      headers: _headers(token),
      body: jsonEncode({"inviteeUuid": inviteeUuid}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response.body);
      throw Exception(data["message"] ?? "Failed to invite rider");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchInviteCandidates(
    String token,
    String rideUuid,
  ) async {
    final response = await http.get(
      Uri.parse("$_apiBaseUrl/participants/$rideUuid/invite-candidates"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final candidates = data["data"] as List? ?? const [];
      return candidates
          .whereType<Map>()
          .map((candidate) => Map<String, dynamic>.from(candidate))
          .toList();
    }

    throw Exception(data["message"] ?? "Failed to load invite candidates");
  }

  static Future<Map<String, dynamic>> fetchInvitationDetails(
    String token,
    int invitationId,
  ) async {
    final response = await http.get(
      Uri.parse("$_apiBaseUrl/participants/invitations/$invitationId"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to fetch invitation details");
  }

  static Future<void> acceptInvitation(String token, int invitationId) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/participants/invitations/$invitationId/accept"),
      headers: _headers(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response.body);
      throw Exception(data["message"] ?? "Failed to accept invitation");
    }
  }

  static Future<void> rejectInvitation(String token, int invitationId) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/participants/invitations/$invitationId/reject"),
      headers: _headers(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response.body);
      throw Exception(data["message"] ?? "Failed to reject invitation");
    }
  }

  static Map<String, dynamic> buildPreRideInfoPayload({
    required Map<String, dynamic> rideGroup,
    required String meetingPoint,
    required String fuelStops,
    required List<String> checkpoints,
    required List<String> rules,
    String notes = "",
  }) {
    String joinOrEmpty(List<String> values) {
      return values.where((value) => value.trim().isNotEmpty).join(", ");
    }

    return {
      "rideType": rideGroup["rideType"],
      "routeType": rideGroup["routeType"],
      "maxRiders": rideGroup["maxRiders"],
      "visibility": rideGroup["visibility"],
      "title": rideGroup["title"],
      "description": rideGroup["description"],
      "startTime": rideGroup["startTime"],
      "meetingPoint": meetingPoint.trim(),
      "fuelStops": fuelStops.trim(),
      "checkpoints": joinOrEmpty(checkpoints),
      "checkpointList": checkpoints.where((item) => item.trim().isNotEmpty).toList(),
      "rules": joinOrEmpty(rules),
      "ruleList": rules.where((item) => item.trim().isNotEmpty).toList(),
      "notes": notes.trim(),
      "updatedAt": DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> savePreRideInfoLocally({
    required Map<String, dynamic> rideGroup,
    required Map<String, dynamic> preRideInfo,
  }) {
    rideGroup["preRideInfo"] = preRideInfo;
    return preRideInfo;
  }

  static Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return {};
    }

    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
