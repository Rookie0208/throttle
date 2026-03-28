import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Throttle';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'A powerful tool for managing and optimizing your network traffic.';

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8080/api/v1";
    }
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080/api/v1";
    }
    return "http://localhost:8080/api/v1";
  }
}
