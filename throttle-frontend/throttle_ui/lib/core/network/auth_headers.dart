import 'package:throttle_ui/features/auth/data/services/auth_service.dart';

/// Resolves a current access token, refreshing it when the 15-minute JWT is near expiry.
class AuthHeaders {
  AuthHeaders._();

  static Future<String?> resolve([String? fallback]) async {
    final fresh = await AuthService.getToken();
    if (fresh != null && fresh.isNotEmpty) {
      return fresh;
    }
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    return null;
  }

  static Future<Map<String, String>> json([String? fallback]) async {
    final token = await resolve(fallback);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
