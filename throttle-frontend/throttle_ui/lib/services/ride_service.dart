import 'dart:convert';
import 'package:http/http.dart' as http;

class RideService {
  static const String baseUrl = "http://localhost:8080/api/v1/rides/create";

  static Future<Map<String, dynamic>> createRide(Map<String, dynamic> rideData, String token) async {
    try {
      final url = Uri.parse(baseUrl);

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // send JWT here
        },
        body: jsonEncode(rideData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["message"] ?? "Failed to create ride"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
