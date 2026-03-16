import 'dart:convert';
import 'package:http/http.dart' as http;

class RideMemberService {

  static const String baseUrl = "http://localhost:8080/api/v1";

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
      Uri.parse("$baseUrl/rides/$rideUuid/members/$userUuid/role"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
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