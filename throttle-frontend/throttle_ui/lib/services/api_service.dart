import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  static Future<String?> _getToken() async {
    return await AuthService.getToken();
  }

  static Future<dynamic> get(String endpoint, {bool authorized = false}) async {
    Map<String, String> headers = {"Content-Type": "application/json"};
    if (authorized) {
      final token = await _getToken();
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    final response = await http.get(
      Uri.parse("${AppConstants.baseUrl}$endpoint"),
      headers: headers,
    );

    return {"status": response.statusCode, "body": response.body};
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool authorized = false,
  }) async {
    Map<String, String> headers = {"Content-Type": "application/json"};

    if (authorized) {
      final token = await _getToken();
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}$endpoint"),
      headers: headers,
      body: jsonEncode(body),
    );

    return {"status": response.statusCode, "body": response.body};
  }
}
