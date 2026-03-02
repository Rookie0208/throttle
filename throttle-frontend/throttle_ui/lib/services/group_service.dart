import 'dart:convert';
import 'package:http/http.dart' as http;

class GroupService {
  static const String baseUrl =
      "http://localhost:8080/api/v1/groups/my";

  static Future<Map<String, dynamic>> fetchMyGroups(String token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
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
}