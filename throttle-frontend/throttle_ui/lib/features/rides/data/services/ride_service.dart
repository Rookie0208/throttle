import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:throttle_ui/core/constants/app_constants.dart';

class RideService {
  static String get _apiBaseUrl => AppConstants.baseUrl;
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

  static Future<void> leaveRide(String token, String rideUuid) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/participants/$rideUuid/leave"),
      headers: _headers(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response.body);
      throw Exception(data["message"] ?? "Failed to leave ride");
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

  static Future<Map<String, dynamic>> fetchRideSession(
    String token,
    String rideUuid,
  ) async {
    final response = await http.get(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/session"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to fetch ride session");
  }

  static Future<Map<String, dynamic>> partialStartRide(
    String token,
    String rideUuid,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/partial-start"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to partial start ride");
  }

  static Future<Map<String, dynamic>> arriveAtStart(
    String token,
    String rideUuid,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/arrive-start"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to mark arrival");
  }

  static Future<Map<String, dynamic>> startRideSession(
    String token,
    String rideUuid,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/start"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to start ride");
  }

  static Future<Map<String, dynamic>> dropRide(
    String token,
    String rideUuid,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/drop"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to drop ride");
  }

  static Future<Map<String, dynamic>> startReturnRide(
    String token,
    String rideUuid,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/return/start"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to start return ride");
  }

  static Future<Map<String, dynamic>> endReturnRide(
    String token,
    String rideUuid,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/return/end"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to complete return ride");
  }

  static Future<Map<String, dynamic>> updateRideLocation(
    String token,
    String rideUuid, {
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/location"),
      headers: _headers(token),
      body: jsonEncode({"latitude": latitude, "longitude": longitude}),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to update ride location");
  }

  static Future<Map<String, dynamic>> advanceCheckpoint(
    String token,
    String rideUuid,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/checkpoints/advance"),
      headers: _headers(token),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to advance checkpoint");
  }

  static Future<void> sendRideAnnouncement(
    String token,
    String rideUuid,
    String message,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/announcement"),
      headers: _headers(token),
      body: jsonEncode({"message": message.trim()}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response.body);
      throw Exception(data["message"] ?? "Failed to send broadcast");
    }
  }

  static Future<Map<String, dynamic>> sendSos(
    String token,
    String rideUuid,
    String message,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/sos"),
      headers: _headers(token),
      body: jsonEncode({"message": message.trim()}),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to send SOS");
  }

  static Future<Map<String, dynamic>> resolveSos(
    String token,
    String rideUuid,
    String resolution,
  ) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/sos/resolve"),
      headers: _headers(token),
      body: jsonEncode({"resolution": resolution.trim().toUpperCase()}),
    );

    final data = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(data["data"] ?? const {});
    }

    throw Exception(data["message"] ?? "Failed to resolve SOS");
  }

  static Future<void> completeRide(String token, String rideUuid) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/complete"),
      headers: _headers(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response.body);
      throw Exception(data["message"] ?? "Failed to complete ride");
    }
  }

  static Future<void> cancelRide(String token, String rideUuid) async {
    final response = await http.post(
      Uri.parse("$_apiBaseUrl/rides/$rideUuid/cancel"),
      headers: _headers(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _decodeBody(response.body);
      throw Exception(data["message"] ?? "Failed to cancel ride");
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
      "checkpointList": checkpoints
          .where((item) => item.trim().isNotEmpty)
          .toList(),
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

  static Future<void> addRideCheckpoint(
    String token,
    String rideUuid,
    String title, {
    double? latitude,
    double? longitude,
  }) async {
    final baseUrl = _apiBaseUrl;
    final response = await http.post(
      Uri.parse('$baseUrl/rides/$rideUuid/checkpoints/custom'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add custom checkpoint: ${response.body}');
    }
  }
}
