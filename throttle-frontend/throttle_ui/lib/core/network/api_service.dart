import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:throttle_ui/core/constants/app_constants.dart';
import 'package:throttle_ui/features/auth/data/services/auth_service.dart';
import 'package:throttle_ui/features/auth/data/services/token_refresh_result.dart';
import 'package:throttle_ui/core/services/logger_service.dart';

class ApiService {
  // Prevent "thundering herd" effect by pausing overlapping refresh requests
  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  static Future<dynamic> get(
    String endpoint, {
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    return _requestWithRetry(
      () async {
        Map<String, String> requestHeaders = {
          "Content-Type": "application/json",
          ...?headers,
        };
        if (authorized) {
          final token = await AuthService.getToken();
          if (token != null) {
            requestHeaders["Authorization"] = "Bearer $token";
          }
        }

        final response = await http.get(
          Uri.parse("${AppConstants.baseUrl}$endpoint"),
          headers: requestHeaders,
        );

        return response;
      },
      needsAuth: authorized,
    );
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    return _requestWithRetry(
      () async {
        Map<String, String> requestHeaders = {
          "Content-Type": "application/json",
          ...?headers,
        };

        if (authorized) {
          final token = await AuthService.getToken();
          if (token != null) {
            requestHeaders["Authorization"] = "Bearer $token";
          }
        }

        final response = await http.post(
          Uri.parse("${AppConstants.baseUrl}$endpoint"),
          headers: requestHeaders,
          body: jsonEncode(body),
        );

        return response;
      },
      needsAuth: authorized,
    );
  }

  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    return _requestWithRetry(
      () async {
        Map<String, String> requestHeaders = {
          "Content-Type": "application/json",
          ...?headers,
        };

        if (authorized) {
          final token = await AuthService.getToken();
          if (token != null) {
            requestHeaders["Authorization"] = "Bearer $token";
          }
        }

        final response = await http.put(
          Uri.parse("${AppConstants.baseUrl}$endpoint"),
          headers: requestHeaders,
          body: jsonEncode(body),
        );

        return response;
      },
      needsAuth: authorized,
    );
  }

  static Future<dynamic> delete(
    String endpoint, {
    bool authorized = false,
    Map<String, String>? headers,
  }) async {
    return _requestWithRetry(
      () async {
        Map<String, String> requestHeaders = {
          "Content-Type": "application/json",
          ...?headers,
        };

        if (authorized) {
          final token = await AuthService.getToken();
          if (token != null) {
            requestHeaders["Authorization"] = "Bearer $token";
          }
        }

        final response = await http.delete(
          Uri.parse("${AppConstants.baseUrl}$endpoint"),
          headers: requestHeaders,
        );

        return response;
      },
      needsAuth: authorized,
    );
  }

  /// Wraps an HTTP request with automatic token refresh logic
  static Future<dynamic> _requestWithRetry(
    Future<http.Response> Function() requestFunc, {
    bool needsAuth = false,
  }) async {
    // 1. Await any in-progress refresh before making the request
    if (_isRefreshing && _refreshCompleter != null) {
      await _refreshCompleter!.future;
    }

    if (needsAuth) {
      await AuthService.ensureValidAccessToken();
    }

    // 2. Make the original request
    http.Response response = await requestFunc();

    // 3. If unauthorized (expired token), try to refresh once more
    if (response.statusCode == 401 && needsAuth) {
      if (!_isRefreshing) {
        Logger.info(
          "Initiating token refresh flow over ApiService due to 401 Unauthorized",
        );
        _isRefreshing = true;
        _refreshCompleter = Completer<bool>();

        final result = await AuthService.refreshToken();
        final success = result == TokenRefreshResult.success;

        _isRefreshing = false;
        _refreshCompleter!.complete(success);

        if (success) {
          Logger.info(
            "Token refreshed globally, retrying the failed 401 request",
          );
          response = await requestFunc();
        } else if (result == TokenRefreshResult.unauthorized) {
          Logger.error("Refresh token expired or revoked. Clearing session.");
          await AuthService.logoutDueToExpiredSession();
        } else {
          Logger.warn(
            "Token refresh failed due to network. Keeping local session.",
          );
        }
      } else {
        Logger.info(
          "Another request is already refreshing the token, waiting...",
        );
        final success = await _refreshCompleter!.future;
        if (success) {
          Logger.info("Queued request retrying after successful token refresh");
          response = await requestFunc();
        }
      }
    }

    return {"status": response.statusCode, "body": response.body};
  }
}
