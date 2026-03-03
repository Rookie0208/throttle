import 'dart:convert';
import 'api_service.dart';
import 'logger_service.dart';

class UserService {
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await ApiService.get('/users/me', authorized: true);

      if (response['status'] == 200 || response['status'] == 201) {
        final decoded = jsonDecode(response['body']);
        if (decoded['status'] == "SUCCESS" && decoded['data'] != null) {
          await Logger.info(
            "User profile successfully loaded for: ${decoded['data']['firstName']}",
          );
          return decoded['data'];
        }
        await Logger.error(
          "Failed to parse user profile. Success flag false or data is null.",
          decoded,
        );
        return {"firstName": "ParsingError", "lastName": decoded.toString()};
      } else {
        await Logger.warn(
          "Received HTTP ${response['status']} from /users/me endpoint. Body: ${response['body']}",
        );
        return {
          "firstName": "HTTP ${response['status']}",
          "lastName": response['body'].toString(),
        };
      }
    } catch (e, stackTrace) {
      await Logger.error(
        "Exception thrown while fetching user profile.",
        e,
        stackTrace,
      );
      return {"firstName": "CatchError", "lastName": e.toString()};
    }
  }
}
