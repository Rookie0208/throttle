import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:throttle_ui/core/constants/app_constants.dart';

class RideMemberService {
  static String get baseUrl => AppConstants.baseUrl;

  // Hardcoded roles list - can be easily updated here without touching UI
  static const List<String> availableRoles = [
    "RIDER", // default
    "NAVIGATOR",
    "MARSHAL",
    "SWEEPER",
    "CO_CAPTAIN",
    "CAPTAIN",
    "ADMIN",
  ];

  static Future<List<String>> fetchRoles(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/rides/roles"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(res.body);
    return List<String>.from(data["data"]);
  }

  static Future<void> updateRole(
    String token,
    String rideUuid,
    String userUuid,
    String role,
  ) async {
    await http.put(
      Uri.parse("$baseUrl/participants/$rideUuid/$userUuid/role"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"role": role}),
    );
  }

  static Future<void> removeMember(
    String token,
    String rideUuid,
    String userUuid,
  ) async {
    await http.delete(
      Uri.parse("$baseUrl/rides/$rideUuid/members/$userUuid"),
      headers: {"Authorization": "Bearer $token"},
    );
  }
}
