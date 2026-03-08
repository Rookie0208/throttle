import 'dart:convert';
import 'package:http/http.dart' as http;

class GroupService {
  static const String baseUrl =
      "http://localhost:8080/api/v1/rides";

  static Future<Map<String, dynamic>> fetchMyGroups(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/my"),
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
      Uri.parse("$baseUrl/$rideUuid/participants"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );
    print("url : "+"$baseUrl/$rideUuid/participants");

    if (response.statusCode == 200) {
      print("Fetch Ride Members Response: ${response.body}");
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch ride members");
    }
  }
}