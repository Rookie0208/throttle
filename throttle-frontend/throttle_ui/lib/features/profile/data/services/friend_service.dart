import 'dart:convert';
import 'package:throttle_ui/core/network/api_service.dart';
import 'package:throttle_ui/core/services/logger_service.dart';

class FriendService {
  static String _traceId(String action) =>
      'friend-$action-${DateTime.now().microsecondsSinceEpoch}';

  static String _ctx(String action, [Map<String, Object?> fields = const {}]) {
    final suffix = fields.entries.map((e) => '${e.key}=${e.value}').join(' ');
    return suffix.isEmpty
        ? '[FRIEND_API] action=$action'
        : '[FRIEND_API] action=$action $suffix';
  }

  /// Sends a friend request to a user by their UUID.
  static Future<bool> sendRequest(String receiverUuid) async {
    final traceId = _traceId('send-request');
    await Logger.info(
      _ctx('send_request_start', {'target': receiverUuid, 'traceId': traceId}),
    );
    final response = await ApiService.post(
      '/friends/request',
      {"receiverUuid": receiverUuid},
      authorized: true,
      headers: {'X-Trace-Id': traceId},
    );

    if (response['status'] == 200) {
      await Logger.info(
        _ctx('send_request_success', {
          'target': receiverUuid,
          'traceId': traceId,
        }),
      );
      return true;
    }
    await Logger.warn(
      _ctx('send_request_failed', {
        'target': receiverUuid,
        'status': response['status'],
        'traceId': traceId,
      }),
    );
    return false;
  }

  /// Accepts a pending friend request by its request ID.
  static Future<bool> acceptRequest(int requestId) async {
    final traceId = _traceId('accept-request');
    await Logger.info(
      _ctx('accept_request_start', {
        'requestId': requestId,
        'traceId': traceId,
      }),
    );
    final response = await ApiService.post(
      '/friends/accept/$requestId',
      {}, // Empty body
      authorized: true,
      headers: {'X-Trace-Id': traceId},
    );

    if (response['status'] == 200) {
      await Logger.info(
        _ctx('accept_request_success', {
          'requestId': requestId,
          'traceId': traceId,
        }),
      );
      return true;
    }
    await Logger.warn(
      _ctx('accept_request_failed', {
        'requestId': requestId,
        'status': response['status'],
        'traceId': traceId,
      }),
    );
    return false;
  }

  /// Rejects a pending friend request by its request ID.
  static Future<bool> rejectRequest(int requestId) async {
    final traceId = _traceId('reject-request');
    await Logger.info(
      _ctx('reject_request_start', {
        'requestId': requestId,
        'traceId': traceId,
      }),
    );
    final response = await ApiService.post(
      '/friends/reject/$requestId',
      {}, // Empty body
      authorized: true,
      headers: {'X-Trace-Id': traceId},
    );

    if (response['status'] == 200) {
      await Logger.info(
        _ctx('reject_request_success', {
          'requestId': requestId,
          'traceId': traceId,
        }),
      );
      return true;
    }
    await Logger.warn(
      _ctx('reject_request_failed', {
        'requestId': requestId,
        'status': response['status'],
        'traceId': traceId,
      }),
    );
    return false;
  }

  static Future<bool> unfriend(String targetUuid) async {
    final traceId = _traceId('unfriend');
    await Logger.info(
      _ctx('unfriend_start', {'target': targetUuid, 'traceId': traceId}),
    );
    final response = await ApiService.delete(
      '/friends/$targetUuid',
      authorized: true,
      headers: {'X-Trace-Id': traceId},
    );

    if (response['status'] == 200) {
      await Logger.info(
        _ctx('unfriend_success', {'target': targetUuid, 'traceId': traceId}),
      );
    } else {
      await Logger.warn(
        _ctx('unfriend_failed', {
          'target': targetUuid,
          'status': response['status'],
          'traceId': traceId,
        }),
      );
    }
    return response['status'] == 200;
  }

  /// Fetches the list of friends for a given user UUID.
  static Future<List<dynamic>> getFriends(String userUuid) async {
    final traceId = _traceId('get-friends');
    await Logger.info(
      _ctx('get_friends_start', {'userId': userUuid, 'traceId': traceId}),
    );
    final response = await ApiService.get(
      '/users/$userUuid/friends',
      authorized: true,
      headers: {'X-Trace-Id': traceId},
    );

    if (response['status'] == 200) {
      final data = jsonDecode(response['body']);
      await Logger.info(
        _ctx('get_friends_success', {
          'userId': userUuid,
          'count': (data['data'] ?? []).length,
          'traceId': traceId,
        }),
      );
      return data['data'] ?? [];
    }
    await Logger.warn(
      _ctx('get_friends_failed', {
        'userId': userUuid,
        'status': response['status'],
        'traceId': traceId,
      }),
    );
    return [];
  }

  /// Fetches pending friend requests for the currently authenticated user.
  static Future<List<dynamic>> getPendingRequests() async {
    final traceId = _traceId('get-pending');
    await Logger.info(_ctx('get_pending_start', {'traceId': traceId}));
    final response = await ApiService.get(
      '/friends/requests/pending',
      authorized: true,
      headers: {'X-Trace-Id': traceId},
    );

    if (response['status'] == 200) {
      final data = jsonDecode(response['body']);
      await Logger.info(
        _ctx('get_pending_success', {
          'count': (data['data'] ?? []).length,
          'traceId': traceId,
        }),
      );
      return data['data'] ?? [];
    }
    await Logger.warn(
      _ctx('get_pending_failed', {
        'status': response['status'],
        'traceId': traceId,
      }),
    );
    return [];
  }

  /// Fetches Neo4j mutual friend recommendations for a given user UUID.
  static Future<List<dynamic>> getRecommendations(String userUuid) async {
    final traceId = _traceId('get-recommendations');
    await Logger.info(
      _ctx('get_recommendations_start', {
        'userId': userUuid,
        'traceId': traceId,
      }),
    );
    final response = await ApiService.get(
      '/users/$userUuid/friends/recommendations',
      authorized: true,
      headers: {'X-Trace-Id': traceId},
    );

    if (response['status'] == 200) {
      final data = jsonDecode(response['body']);
      await Logger.info(
        _ctx('get_recommendations_success', {
          'userId': userUuid,
          'count': (data['data'] ?? []).length,
          'traceId': traceId,
        }),
      );
      return data['data'] ?? [];
    }
    await Logger.warn(
      _ctx('get_recommendations_failed', {
        'userId': userUuid,
        'status': response['status'],
        'traceId': traceId,
      }),
    );
    return [];
  }

  /// Fetches the mutual friends count between the current user and target user
  static Future<int> getMutualFriendsCount(String targetUuid) async {
    final traceId = _traceId('get-mutual-count');
    await Logger.info(
      _ctx('get_mutual_count_start', {
        'target': targetUuid,
        'traceId': traceId,
      }),
    );
    final response = await ApiService.get(
      '/friends/mutual/$targetUuid',
      authorized: true,
      headers: {'X-Trace-Id': traceId},
    );

    if (response['status'] == 200) {
      final data = jsonDecode(response['body']);
      await Logger.info(
        _ctx('get_mutual_count_success', {
          'target': targetUuid,
          'count': data['data'] ?? 0,
          'traceId': traceId,
        }),
      );
      return data['data'] ?? 0;
    }
    await Logger.warn(
      _ctx('get_mutual_count_failed', {
        'target': targetUuid,
        'status': response['status'],
        'traceId': traceId,
      }),
    );
    return 0;
  }

  static Future<Map<String, dynamic>> getRelationshipStatus(
    String targetUuid,
  ) async {
    final traceId = _traceId('get-relationship');
    await Logger.info(
      _ctx('get_relationship_start', {
        'target': targetUuid,
        'traceId': traceId,
      }),
    );
    final response = await ApiService.get(
      '/friends/status/$targetUuid',
      authorized: true,
      headers: {'X-Trace-Id': traceId},
    );

    if (response['status'] == 200) {
      final data = jsonDecode(response['body']);
      await Logger.info(
        _ctx('get_relationship_success', {
          'target': targetUuid,
          'statusValue': (data['data'] ?? const {})['status'] ?? 'unknown',
          'traceId': traceId,
        }),
      );
      return Map<String, dynamic>.from(data['data'] ?? const {});
    }

    await Logger.warn(
      _ctx('get_relationship_failed', {
        'target': targetUuid,
        'status': response['status'],
        'traceId': traceId,
      }),
    );
    return {'status': 'unknown'};
  }
}
