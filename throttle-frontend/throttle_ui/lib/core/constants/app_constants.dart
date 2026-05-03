import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'Throttle';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'A powerful tool for managing and optimizing your network traffic.';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';

  static String get baseUrl {
    final configuredBaseUrl = apiBaseUrl.trim();
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  static String get whatsappCommunityUrl =>
      dotenv.env['WHATSAPP_COMMUNITY_URL'] ??
      'https://chat.whatsapp.com/BvFnvej1Oup4bSxulL5c6U';
}
