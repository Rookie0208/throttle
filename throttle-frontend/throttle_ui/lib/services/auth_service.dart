import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/logger_service.dart';

class AuthService {
  static String get baseUrl =>
      "${dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1'}/auth";
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
        body: jsonEncode({"email": email, "password": password}),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 🔥 Extract token from nested data object
        final token = decoded["data"]?["token"];

        if (token == null) {
          return {"success": false, "message": "Token not found in response"};
        }

        await saveToken(token);

        return {"success": true, "data": decoded["data"]};
      } else {
        return {
          "success": false,
          "message": decoded["message"] ?? "Login failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // ================= GOOGLE AUTH =================
  static final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  static bool _isGoogleSignInInitialized = false;

  static Future<void> initGoogleSignIn() async {
    if (!_isGoogleSignInInitialized) {
      await googleSignIn.initialize(
        clientId: dotenv.env['GOOGLE_CLIENT_ID'] ?? "",
      );
      _isGoogleSignInInitialized = true;
    }
  }

  static Future<Map<String, dynamic>> initiateGoogleAuth({
    String? webIdToken,
  }) async {
    try {
      String? idToken = webIdToken;

      if (idToken == null) {
        final GoogleSignInAccount account = await googleSignIn.authenticate();
        final GoogleSignInAuthentication auth = account.authentication;
        idToken = auth.idToken;
      }

      if (idToken == null) {
        return {
          "success": false,
          "message": "Failed to retrieve Google ID Token",
        };
      }

      final url = Uri.parse("$baseUrl/google/initiate");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded["data"];

        // If it's a login, save the token
        if (data["token"] != null) {
          await saveToken(data["token"]);
        }

        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": decoded["message"] ?? "Google verification failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error signing in with Google: $e"};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/google/verify-otp");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"success": true, "data": decoded["data"]};
      } else {
        return {
          "success": false,
          "message": decoded["message"] ?? "Invalid OTP",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Network error verification failed: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> completeGoogleRegistration({
    required String email,
    required String firstName,
    required String lastName,
    required String pronoun,
    required String bikeType,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/google/complete-registration");

      final body = {
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
        "gender": _getGenderFromPronoun(pronoun),
        "pronoun": pronoun,
        "bikeType": bikeType,
        "role": "RIDER",
        "city": null,
        "experienceYears": 0,
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = decoded["data"]?["token"];
        if (token != null) {
          await saveToken(token);
        }
        return {"success": true, "data": decoded["data"]};
      } else {
        return {
          "success": false,
          "message": decoded["message"] ?? "Registration failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // ================= SAVE TOKEN & DATA =================
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
      return {"success": true, "data": data};
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
