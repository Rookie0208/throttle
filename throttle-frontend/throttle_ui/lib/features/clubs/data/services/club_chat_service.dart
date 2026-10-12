import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:throttle_ui/core/constants/app_constants.dart';
import 'package:throttle_ui/core/network/auth_headers.dart';

class ClubChatService {
  StompClient? _stompClient;
  bool isConnected = false;
  String? _channelUuid;

  static Future<List<dynamic>> fetchMessages(String channelUuid) async {
    final token = await AuthHeaders.resolve();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/clubs/chat/$channelUuid'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Failed to load club messages');
  }

  void connect({
    required String channelUuid,
    required String token,
    required void Function(dynamic message) onMessageReceived,
  }) {
    disconnect();
    _channelUuid = channelUuid;
    _openSocket(
      channelUuid: channelUuid,
      token: token,
      onMessageReceived: onMessageReceived,
    );
  }

  Future<void> _openSocket({
    required String channelUuid,
    required String token,
    required void Function(dynamic message) onMessageReceived,
  }) async {
    final resolvedToken = await AuthHeaders.resolve(token);
    if (resolvedToken == null) {
      return;
    }

    final socketUrl = AppConstants.baseUrl.replaceAll('/api/v1', '/ws-friends');
    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: socketUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $resolvedToken'},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (_) {
          isConnected = true;
          _stompClient?.subscribe(
            destination: '/topic/club.$channelUuid',
            callback: (frame) {
              if (frame.body == null) return;
              onMessageReceived(jsonDecode(frame.body!));
            },
          );
        },
        onDisconnect: (_) => isConnected = false,
        onWebSocketError: (_) => isConnected = false,
        onStompError: (_) => isConnected = false,
      ),
    );

    _stompClient?.activate();
  }

  void sendMessage({required String text}) {
    if (!isConnected || _stompClient == null || _channelUuid == null) {
      return;
    }
    final payload = {
      'groupId': _channelUuid,
      'message': text,
      'messageType': 'TEXT',
      'uuid': DateTime.now().microsecondsSinceEpoch.toString(),
    };
    _stompClient?.send(
      destination: '/app/club-chat.send',
      body: jsonEncode(payload),
    );
  }

  void disconnect() {
    isConnected = false;
    _stompClient?.deactivate();
    _stompClient = null;
  }
}
