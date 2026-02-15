import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<dynamic> post(
      String endpoint,
      Map<String, dynamic> body,
      {bool authorized = false}) async {

    Map<String, String> headers = {
      "Content-Type": "application/json"
    };

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

    return {
      "status": response.statusCode,
      "body": response.body
    };
  }
}
