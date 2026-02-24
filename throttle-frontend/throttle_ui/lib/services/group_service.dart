import 'dart:convert';
import 'package:http/http.dart' as http;

class GroupService {
  static const String baseUrl = "http://localhost:8080/api/v1/groups";

  // Fetch groups created by user
  static Future<List<Map<String, dynamic>>> fetchGroups(String token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming API returns {"active": [...], "archived": [...]}
        List<Map<String, dynamic>> active = List<Map<String, dynamic>>.from(data["active"]);
        List<Map<String, dynamic>> archived = List<Map<String, dynamic>>.from(data["archived"]);
        return [...active, ...archived];
      } else {
        return [];
      }
    } catch (e) {
      print(e);
      return [];
    }
  }
}