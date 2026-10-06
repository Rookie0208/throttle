import 'package:jwt_decoder/jwt_decoder.dart';

class UserSession {
  static String? userId;
  static String? token;

  static void init(String jwtToken) {
    token = jwtToken;
    final decoded = JwtDecoder.decode(jwtToken);
    userId = decoded["sub"] ?? decoded["userId"];
  }

  static void clear() {
    userId = null;
    token = null;
  }
}