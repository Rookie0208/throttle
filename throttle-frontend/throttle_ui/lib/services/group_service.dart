import 'dart:convert';
import 'package:http/http.dart' as http;

class GroupService {
  static const String baseUrl =
      "http://localhost:8080/api/v1";

      static Future<void> updateRide(
  String token,
  String rideUuid,
  Map payload,
) async {

  await http.put(
    Uri.parse("$baseUrl/rides/$rideUuid"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    },
    body: jsonEncode(payload),
  );
}

  static Future<Map<String, dynamic>> fetchMyGroups(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rides/my"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
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
      String token, String rideUuid) async {

    final response = await http.get(
      Uri.parse("$baseUrl/participants/$rideUuid"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );
    print("url : $baseUrl/participants/$rideUuid");

    if (response.statusCode == 200) {
      print("Fetch Ride Members Response: ${response.body}");
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch ride members");
    }
  }
}