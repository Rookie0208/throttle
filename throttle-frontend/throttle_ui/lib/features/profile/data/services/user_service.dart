import 'dart:convert';
import 'package:throttle_ui/core/network/api_service.dart';
import 'package:throttle_ui/core/services/logger_service.dart';

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

  static Future<Map<String, dynamic>?> getProfileByUuid(String userUuid) async {
    try {
      final response = await ApiService.get('/users/$userUuid', authorized: true);

      if (response['status'] == 200 || response['status'] == 201) {
        final decoded = jsonDecode(response['body']);
        if (decoded['status'] == "SUCCESS" && decoded['data'] != null) {
          return decoded['data'];
        }
      }
      await Logger.warn(
        "Failed to load public profile $userUuid: ${response['status']} ${response['body']}",
      );
    } catch (e, stackTrace) {
      await Logger.error(
        "Exception thrown while fetching public profile $userUuid.",
        e,
        stackTrace,
      );
    }
    return null;
  }

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.put('/users/me', data, authorized: true);
      if (response['status'] == 200 || response['status'] == 201) {
        await Logger.info("Profile updated successfully.");
        return true;
      }
      await Logger.warn("Update profile failed: ${response['status']} - ${response['body']}");
    } catch (e, st) {
      await Logger.error("Exception during update profile", e, st);
    }
    return false;
  }
}
