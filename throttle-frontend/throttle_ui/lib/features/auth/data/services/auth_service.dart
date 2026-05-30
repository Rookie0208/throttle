import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:throttle_ui/core/constants/app_constants.dart';
import 'package:throttle_ui/core/globals.dart';
import 'package:throttle_ui/core/services/logger_service.dart';

class AuthService {
  static String get baseUrl => "${AppConstants.baseUrl}/auth";
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = "jwt_token";
  static const String _refreshTokenKey = "refresh_token";

  // ================= REGISTER =================
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String riderId,
    String? lastName,
    required String pronoun,
    required String email,
    required String password,
    int? bikeMasterId,
    String? bikeBrand,
    String? bikeModel,
    String? bikeVariant,
    String? bikeCategory,
    String? bikeType,
    int? bikeYear,
    int? bikeEngineCc,
    int? experienceYears,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/register");
print("amit.baseURL : "+url.toString());
      final body = {
        "firstName": firstName,
        "lastName": lastName ?? "",
        "riderId": riderId.trim().toLowerCase(),
        "gender": _getGenderFromPronoun(pronoun),
        "pronoun": pronoun,
        "email": email,
        "password": password,
        "city": null,
        "experienceYears": experienceYears ?? 0,
        "emergencyContacts": [],
        "bikeMasterId": bikeMasterId,
        "bikeBrand": bikeBrand,
        "bikeModel": bikeModel,
        "bikeVariant": bikeVariant,
        "bikeCategory": bikeCategory,
        "bikeType": bikeType,
        "bikeYear": bikeYear,
        "bikeEngineCc": bikeEngineCc,
        "role": "RIDER",
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final decoded = _decodeResponse(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded["data"];
        if (data != null) {
          final token = data["token"];
          final refreshToken = data["refreshToken"];
          if (token != null && refreshToken != null) {
            await saveTokens(token, refreshToken);
          }
        }
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": _extractMessage(decoded, "Registration failed"),
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message":
            "Unable to reach the server. Please check your connection and try again.",
      };
    }
  }

  // ================= LOGIN =================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    Logger.info("Attempting login for user: $email");
    try {
      final url = Uri.parse("$baseUrl/login");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final decoded = _decodeResponse(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = decoded["data"]?["token"];
        final refreshToken = decoded["data"]?["refreshToken"];

        if (token == null || refreshToken == null) {
          Logger.error("Token missing from login response payload");
          return {"success": false, "message": "Token not found in response"};
        }

        await saveTokens(token, refreshToken);
        Logger.info("Login successful. Tokens securely stored.");

        return {"success": true, "data": decoded["data"]};
      } else {
        Logger.warn("Login failed with status ${response.statusCode}");
        return {
          "success": false,
          "message": _extractMessage(decoded, "Login failed"),
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message":
            "Unable to reach the server. Please check your connection and try again.",
      };
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
      String idToken = webIdToken ?? "";

      if (idToken.isEmpty) {
        // use authenticate to match original implementation version
        final GoogleSignInAccount account = await googleSignIn.authenticate();
        final GoogleSignInAuthentication auth = account.authentication;
        idToken = auth.idToken ?? "";
      }

      if (idToken.isEmpty) {
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

      final decoded = _decodeResponse(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded["data"];

        // If it's a login, save the token
        if (data["token"] != null && data["refreshToken"] != null) {
          Logger.info("Google verification success. Storing tokens.");
          await saveTokens(data["token"], data["refreshToken"]);
        }

        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": _extractMessage(decoded, "Google verification failed"),
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message":
            "Unable to complete Google sign-in right now. Please try again.",
      };
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

      final decoded = _decodeResponse(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {"success": true, "data": decoded["data"]};
      } else {
        return {
          "success": false,
          "message": _extractMessage(decoded, "Invalid OTP"),
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message":
            "Unable to verify OTP right now. Please check your connection and try again.",
      };
    }
  }

  static Map<String, dynamic> _decodeResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  static String _extractMessage(Map<String, dynamic> decoded, String fallback) {
    final topLevel = decoded["message"]?.toString().trim();
    if (topLevel != null && topLevel.isNotEmpty) {
      return topLevel;
    }

    final error = decoded["error"];
    if (error is Map<String, dynamic>) {
      final detail = error["errorMessage"]?.toString().trim();
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }
    }

    return fallback;
  }

  static Future<Map<String, dynamic>> completeGoogleRegistration({
    required String email,
    required String firstName,
    required String lastName,
    required String riderId,
    required String pronoun,
    int? bikeMasterId,
    String? bikeBrand,
    String? bikeModel,
    String? bikeVariant,
    String? bikeCategory,
    String? bikeType,
    int? bikeYear,
    int? bikeEngineCc,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/google/complete-registration");

      final body = {
        "email": email,
        "firstName": firstName,
        "lastName": lastName,
        "riderId": riderId.trim().toLowerCase(),
        "gender": _getGenderFromPronoun(pronoun),
        "pronoun": pronoun,
        "bikeMasterId": bikeMasterId,
        "bikeBrand": bikeBrand,
        "bikeModel": bikeModel,
        "bikeVariant": bikeVariant,
        "bikeCategory": bikeCategory,
        "bikeType": bikeType,
        "bikeYear": bikeYear,
        "bikeEngineCc": bikeEngineCc,
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
        final refreshToken = decoded["data"]?["refreshToken"];
        if (token != null && refreshToken != null) {
          await saveTokens(token, refreshToken);
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

  // ================= SAVE TOKENS & DATA =================
  static Future<void> saveTokens(String token, String refreshToken) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    UserSession.init(token);
  }

  // ================= GET TOKENS =================
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // ================= REFRESH TOKEN =================
  static Future<bool> refreshToken() async {
    Logger.info("Attempting to refresh access token...");
    try {
      final currentRefreshToken = await getRefreshToken();
      if (currentRefreshToken == null) {
        Logger.warn("No refresh token found locally. Cannot refresh.");
        return false;
      }

      final url = Uri.parse("$baseUrl/refresh");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": currentRefreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final newToken = decoded["data"]?["accessToken"];
        final newRefreshToken = decoded["data"]?["refreshToken"];

        if (newToken != null && newRefreshToken != null) {
          Logger.info(
            "Successfully received new tokens. Storing to secure storage.",
          );
          await saveTokens(newToken, newRefreshToken);
          return true;
        }
      }
      // If refresh failed (e.g., token expired or revoked in DB)
      Logger.warn(
        "Refresh request rejected by server. Status: ${response.statusCode}",
      );
      return false;
    } catch (e) {
      Logger.error("Network fail during refresh token call", e);
      return false; // Network fail, maybe retry later
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    Logger.info("Initiating secure logout...");
    try {
      final accessToken = await getToken();
      final refreshToken = await getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        final url = Uri.parse("$baseUrl/logout");
        await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization":
                "Bearer $accessToken", // Needs access token for intercept filter
          },
          body: jsonEncode({"refreshToken": refreshToken}),
        );
      }
    } catch (e) {
      Logger.warn("Network completely failed during logout backend call: $e");
      // Ignored: gracefully proceed to clear local token even if network fails
    }

    Logger.info("Clearing local secure storage tokens");
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    // Disconnect google sign-in safely
    try {
      await googleSignIn.signOut();
    } catch (e) {
      Logger.warn("Google sign out skipped: $e");
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
