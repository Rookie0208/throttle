import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:throttle_ui/core/constants/app_constants.dart';

class SubGroupService {
  static String get baseUrl => AppConstants.baseUrl;

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
    final Map<String, dynamic> res = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(res["data"] ?? const {});
    }
    throw Exception(res["message"] ?? "Failed to create subgroup");
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

  static Future<Map<String, dynamic>> fetchMainGroupDetails(
    String token,
    String rideUuid,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/rides/$rideUuid/main-group"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      return Map<String, dynamic>.from(res["data"] ?? const {});
    }

    throw Exception("Failed to load main group details");
  }

  static Future<Map<String, dynamic>> joinSubGroup(
    String token,
    String groupUuid,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/rides/groups/$groupUuid/join"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final Map<String, dynamic> res = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(res["data"] ?? const {});
    }

    throw Exception(res["message"] ?? "Failed to join subgroup");
  }

  static Future<void> leaveSubGroup(String token, String groupUuid) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/rides/groups/$groupUuid/leave"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      throw Exception(res["message"] ?? "Failed to leave subgroup");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchJoinRequests(
    String token,
    String groupUuid,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/rides/groups/$groupUuid/join-requests"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final Map<String, dynamic> res = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List requests = res["data"] ?? [];
      return List<Map<String, dynamic>>.from(requests);
    }

    throw Exception(res["message"] ?? "Failed to load join requests");
  }

  static Future<Map<String, dynamic>> fetchJoinRequestDetails(
    String token,
    int requestId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/rides/join-requests/$requestId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final Map<String, dynamic> res = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(res["data"] ?? const {});
    }

    throw Exception(res["message"] ?? "Failed to load join request details");
  }

  static Future<void> approveJoinRequest(
    String token,
    String groupUuid,
    int requestId,
  ) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/rides/groups/$groupUuid/join-requests/$requestId/approve",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      throw Exception(res["message"] ?? "Failed to approve join request");
    }
  }

  static Future<void> approveJoinRequestById(
    String token,
    int requestId,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/rides/join-requests/$requestId/approve"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      throw Exception(res["message"] ?? "Failed to approve join request");
    }
  }

  static Future<void> rejectJoinRequest(
    String token,
    String groupUuid,
    int requestId,
  ) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/rides/groups/$groupUuid/join-requests/$requestId/reject",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      throw Exception(res["message"] ?? "Failed to reject join request");
    }
  }

  static Future<void> rejectJoinRequestById(String token, int requestId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/rides/join-requests/$requestId/reject"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      throw Exception(res["message"] ?? "Failed to reject join request");
    }
  }

  static Future<Map<String, dynamic>> renameGroup(
    String token,
    String groupUuid,
    String name,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/rides/groups/$groupUuid"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"name": name}),
    );

    final Map<String, dynamic> res = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(res["data"] ?? const {});
    }

    throw Exception(res["message"] ?? "Failed to update group");
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

  static Future<void> addSubGroupMembers(
    String token,
    String groupUuid,
    List<String> memberUuids,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/rides/groups/$groupUuid/members"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"memberUuids": memberUuids}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      throw Exception(res["message"] ?? "Failed to add subgroup members");
    }
  }
}
