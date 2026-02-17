import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://localhost:8080/api/v1/auth";
  static const String _tokenKey = "jwt_token";

  // ================= REGISTER =================
  static Future<Map<String, dynamic>> register({
    required String firstName,
    String? lastName,
    String? pronoun,
    required String email,
    required String password,
    String? bikeType,
    int? experienceYears,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/register");

      final body = {
        "firstName": firstName,
        "lastName": lastName ?? "",
        "gender": _getGenderFromPronoun(pronoun),
        "pronoun": pronoun ?? "",
        "email": email,
        "password": password,
        "city": null,
        "experienceYears": experienceYears ?? 0,
        "emergencyContacts": [],
        "bikeType": bikeType ?? "",
        "role": "RIDER",
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // ================= LOGIN =================
  static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  try {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 🔥 Extract token from nested data object
      final token = decoded["data"]?["token"];

      if (token == null) {
        return {
          "success": false,
          "message": "Token not found in response"
        };
      }

      await saveToken(token);

      return {
        "success": true,
        "data": decoded["data"],
      };
    } else {
      return {
        "success": false,
        "message": decoded["message"] ?? "Login failed"
      };
    }
  } catch (e) {
    return {
      "success": false,
      "message": "Network error: $e"
    };
  }
}


  // ================= SAVE TOKEN =================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // ================= GET TOKEN =================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ================= HANDLE RESPONSE =================
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        "success": true,
        "data": data,
      };
    } else {
      return {
        "success": false,
        "message": data["message"] ?? "Something went wrong",
      };
    }
  }

  // ================= GENDER FROM PRONOUN =================
  static String _getGenderFromPronoun(String? pronoun) {
    switch (pronoun) {
      case "He/Him":
        return "MALE";
      case "She/Her":
        return "FEMALE";
      case "They/Them":
        return "OTHER";
      default:
        return "OTHER";
    }
  }
}
