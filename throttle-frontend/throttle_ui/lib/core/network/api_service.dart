import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:throttle_ui/core/constants/app_constants.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/core/services/logger_service.dart';

class ApiService {
  // Prevent "thundering herd" effect by pausing overlapping refresh requests
  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  static Future<dynamic> get(String endpoint, {bool authorized = false}) async {
    return _requestWithRetry(() async {
      Map<String, String> headers = {"Content-Type": "application/json"};
      if (authorized) {
        final token = await AuthService.getToken();
        if (token != null) {
          headers["Authorization"] = "Bearer $token";
        }
      }

      final response = await http.get(
        Uri.parse("${AppConstants.baseUrl}$endpoint"),
        headers: headers,
      );

      return response;
    });
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool authorized = false,
  }) async {
    return _requestWithRetry(() async {
      Map<String, String> headers = {"Content-Type": "application/json"};

      if (authorized) {
        final token = await AuthService.getToken();
        if (token != null) {
          headers["Authorization"] = "Bearer $token";
        }
      }

      final response = await http.post(
        Uri.parse("${AppConstants.baseUrl}$endpoint"),
        headers: headers,
        body: jsonEncode(body),
      );

      return response;
    });
  }

  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool authorized = false,
  }) async {
    return _requestWithRetry(() async {
      Map<String, String> headers = {"Content-Type": "application/json"};

      if (authorized) {
        final token = await AuthService.getToken();
        if (token != null) {
          headers["Authorization"] = "Bearer $token";
        }
      }

      final response = await http.put(
        Uri.parse("${AppConstants.baseUrl}$endpoint"),
        headers: headers,
        body: jsonEncode(body),
      );

      return response;
    });
  }

  /// Wraps an HTTP request with automatic token refresh logic
  static Future<dynamic> _requestWithRetry(
      Future<http.Response> Function() requestFunc) async {
    // 1. Await any in-progress refresh before making the request
    if (_isRefreshing && _refreshCompleter != null) {
      await _refreshCompleter!.future;
    }

    // 2. Make the original request
    http.Response response = await requestFunc();

    // 3. If unauthorized (expired token), try to refresh
    if (response.statusCode == 401) {
      if (!_isRefreshing) {
        Logger.info("Initiating token refresh flow over ApiService due to 401 Unauthorized");
        _isRefreshing = true;
        _refreshCompleter = Completer<bool>();

        bool success = await AuthService.refreshToken();

        _isRefreshing = false;
        _refreshCompleter!.complete(success);

        if (success) {
          Logger.info("Token refreshed globally, retrying the failed 401 request");
          // Retry the request after successful refresh
          response = await requestFunc();
        } else {
          Logger.error("Token refresh failed. Forcing local logout.");
          // Refresh totally failed (e.g. session revoked in DB). Force logout locally.
          await AuthService.logout();
        }
      } else {
        Logger.info("Another request is already refreshing the token, waiting...");
        // Another request is already refreshing the token, wait for it
        bool success = await _refreshCompleter!.future;
        if (success) {
          Logger.info("Queued request retrying after successful token refresh");
          response = await requestFunc(); // Retry with new token
        }
      }
    }

    return {"status": response.statusCode, "body": response.body};
  }
}
