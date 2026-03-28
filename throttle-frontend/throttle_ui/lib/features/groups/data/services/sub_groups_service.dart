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
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create subgroup");
    }
  }

  static Future<Map<String, dynamic>> fetchSubGroupDetails(
    String token,
    String groupUuid,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/rides/groups/$groupUuid"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      return Map<String, dynamic>.from(res["data"] ?? const {});
    }

    throw Exception("Failed to load subgroup details");
  }

  static Future<List<Map<String, dynamic>>> fetchSubGroupMembers(
    String token,
    String groupUuid,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/rides/groups/$groupUuid/members"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      final List members = res["data"] ?? [];
      return List<Map<String, dynamic>>.from(members);
    }

    throw Exception("Failed to load subgroup members");
  }

  static Future<void> updateSubGroupMemberRole(
    String token,
    String groupUuid,
    String userUuid,
    String role,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/rides/groups/$groupUuid/members/$userUuid/role"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"role": role}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      throw Exception(res["message"] ?? "Failed to update subgroup role");
    }
  }

  static Future<void> removeSubGroupMember(
    String token,
    String groupUuid,
    String userUuid,
  ) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/rides/groups/$groupUuid/members/$userUuid"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      throw Exception(res["message"] ?? "Failed to remove subgroup member");
    }
  }
}
