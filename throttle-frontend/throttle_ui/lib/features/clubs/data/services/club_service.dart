import 'dart:convert';

import 'package:throttle_ui/core/network/api_service.dart';

class ClubService {
  static Future<List<Map<String, dynamic>>> fetchMyClubs() async {
    final response = await ApiService.get('/clubs/my', authorized: true);
    return _decodeListResponse(
      response,
      fallbackMessage: 'Failed to load clubs',
    );
  }

  static Future<List<Map<String, dynamic>>> discoverClubs([
    String query = '',
  ]) async {
    final safeQuery = query.trim();
    final endpoint = safeQuery.isEmpty
        ? '/clubs/discover'
        : '/clubs/discover?query=${Uri.encodeQueryComponent(safeQuery)}';
    final response = await ApiService.get(endpoint, authorized: true);
    return _decodeListResponse(
      response,
      fallbackMessage: 'Failed to discover clubs',
    );
  }

  static Future<Map<String, dynamic>> createClub(
    Map<String, dynamic> payload,
  ) async {
    final response = await ApiService.post('/clubs', payload, authorized: true);
    return _decodeMapResponse(
      response,
      fallbackMessage: 'Failed to create club',
    );
  }

  static Future<Map<String, dynamic>> fetchClubDetails(String clubUuid) async {
    final response = await ApiService.get('/clubs/$clubUuid', authorized: true);
    return _decodeMapResponse(
      response,
      fallbackMessage: 'Failed to load club details',
    );
  }

  static Future<List<Map<String, dynamic>>> fetchMembers(
    String clubUuid,
  ) async {
    final response = await ApiService.get(
      '/clubs/$clubUuid/members',
      authorized: true,
    );
    return _decodeListResponse(
      response,
      fallbackMessage: 'Failed to load club members',
    );
  }

  static Future<List<Map<String, dynamic>>> searchMemberCandidates(
    String clubUuid,
    String query,
  ) async {
    final safeQuery = query.trim();
    final endpoint = safeQuery.isEmpty
        ? '/clubs/$clubUuid/member-candidates'
        : '/clubs/$clubUuid/member-candidates?query=${Uri.encodeQueryComponent(safeQuery)}';
    final response = await ApiService.get(endpoint, authorized: true);
    return _decodeListResponse(
      response,
      fallbackMessage: 'Failed to search riders',
    );
  }

  static Future<void> addMembers(
    String clubUuid,
    List<String> userUuids,
  ) async {
    final response = await ApiService.post('/clubs/$clubUuid/members', {
      'userUuids': userUuids,
    }, authorized: true);
    _ensureSuccess(response, fallbackMessage: 'Failed to add members');
  }

  static Future<void> updateMemberRole(
    String clubUuid,
    String userUuid,
    String role,
  ) async {
    final response = await ApiService.put(
      '/clubs/$clubUuid/members/$userUuid/role',
      {'role': role},
      authorized: true,
    );
    _ensureSuccess(response, fallbackMessage: 'Failed to update member role');
  }

  static Future<void> removeMember(String clubUuid, String userUuid) async {
    final response = await ApiService.delete(
      '/clubs/$clubUuid/members/$userUuid',
      authorized: true,
    );
    _ensureSuccess(response, fallbackMessage: 'Failed to remove member');
  }

  static Future<void> joinClub(String clubUuid) async {
    final response = await ApiService.post(
      '/clubs/$clubUuid/join',
      const {},
      authorized: true,
    );
    _ensureSuccess(response, fallbackMessage: 'Failed to join club');
  }

  static Future<void> leaveClub(String clubUuid) async {
    final response = await ApiService.post(
      '/clubs/$clubUuid/leave',
      const {},
      authorized: true,
    );
    _ensureSuccess(response, fallbackMessage: 'Failed to leave club');
  }

  static Future<List<Map<String, dynamic>>> fetchSubgroups(
    String clubUuid,
  ) async {
    final response = await ApiService.get(
      '/clubs/$clubUuid/subgroups',
      authorized: true,
    );
    return _decodeListResponse(
      response,
      fallbackMessage: 'Failed to load subgroups',
    );
  }

  static Future<Map<String, dynamic>> createSubgroup(
    String clubUuid,
    Map<String, dynamic> payload,
  ) async {
    final response = await ApiService.post(
      '/clubs/$clubUuid/subgroups',
      payload,
      authorized: true,
    );
    return _decodeMapResponse(
      response,
      fallbackMessage: 'Failed to create subgroup',
    );
  }

  static Future<List<Map<String, dynamic>>> fetchSubgroupMembers(
    String subgroupUuid,
  ) async {
    final response = await ApiService.get(
      '/clubs/subgroups/$subgroupUuid/members',
      authorized: true,
    );
    return _decodeListResponse(
      response,
      fallbackMessage: 'Failed to load subgroup members',
    );
  }

  static Map<String, dynamic> _decodeBody(Map<String, dynamic> response) {
    final body = response['body']?.toString() ?? '{}';
    return body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(body));
  }

  static List<Map<String, dynamic>> _decodeListResponse(
    Map<String, dynamic> response, {
    required String fallbackMessage,
  }) {
    final decoded = _decodeBody(response);
    if ((response['status'] as int) >= 200 &&
        (response['status'] as int) < 300) {
      final list = decoded['data'] as List? ?? const [];
      return list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    throw Exception(decoded['message'] ?? fallbackMessage);
  }

  static Map<String, dynamic> _decodeMapResponse(
    Map<String, dynamic> response, {
    required String fallbackMessage,
  }) {
    final decoded = _decodeBody(response);
    if ((response['status'] as int) >= 200 &&
        (response['status'] as int) < 300) {
      return Map<String, dynamic>.from(decoded['data'] ?? const {});
    }
    throw Exception(decoded['message'] ?? fallbackMessage);
  }

  static void _ensureSuccess(
    Map<String, dynamic> response, {
    required String fallbackMessage,
  }) {
    final decoded = _decodeBody(response);
    if ((response['status'] as int) < 200 ||
        (response['status'] as int) >= 300) {
      throw Exception(decoded['message'] ?? fallbackMessage);
    }
  }
}
