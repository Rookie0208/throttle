import 'dart:convert';
import 'package:http/http.dart' as http;

class SubGroupService {
  static const String baseUrl = "http://localhost:8080/api/v1";

  /// FETCH SUBGROUPS
  static Future<List<Map<String, dynamic>>> fetchSubGroups(
  String token,
  String groupUuid,
) async {
  final response = await http.get(
    Uri.parse("$baseUrl/rides/$groupUuid/subgroups"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> res = jsonDecode(response.body);
    
    // Extract the `data` list
    final List subGroups = res['data'] ?? [];

    // Make sure it is a List<Map<String, dynamic>>
    return List<Map<String, dynamic>>.from(subGroups);
  } else {
    throw Exception("Failed to load subgroups");
  }
}

  /// CREATE SUBGROUP
  static Future<Map<String, dynamic>> createSubGroup(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/rides/subgroup"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );
print("url : $baseUrl/rides/subgroup");
 print("STATUS CODE: ${response.statusCode}");
  print("BODY: ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create subgroup");
    }
  }
}