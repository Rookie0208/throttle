import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://localhost:8080/api/v1/auth";

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
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
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
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else if (response.statusCode == 401) {
      return {"success": false, "message": "Wrong email or password"};
    } else {
      return {"success": false, "message": "Login failed (${response.statusCode})"};
    }
  } catch (e) {
    return {"success": false, "message": "Network error: $e"};
  }
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
