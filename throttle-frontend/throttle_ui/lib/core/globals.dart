import 'package:jwt_decoder/jwt_decoder.dart';

class UserSession {
  static String? userId;
  static String? token;

  static void init(String jwtToken) {
    token = jwtToken;

    final decoded = JwtDecoder.decode(jwtToken);

    print("JWT DATA => $decoded");

    /// change key if needed
    userId = decoded["sub"] ?? decoded["userId"];
  }
}