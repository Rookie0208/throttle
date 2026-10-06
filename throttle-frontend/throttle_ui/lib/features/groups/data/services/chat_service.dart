import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:throttle_ui/core/constants/app_constants.dart';
import 'package:throttle_ui/core/network/auth_headers.dart';

class ChatService {
  StompClient? stompClient;
  bool isConnected = false;

  String? _groupId;

  static Future<List<dynamic>> fetchMessages(String groupId) async {
    final token = await AuthHeaders.resolve();

    final response = await http.get(
      Uri.parse("${AppConstants.baseUrl}/chat/$groupId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load messages");
  }

  void connect({
    required String groupId,
    required String token,
    required Function(dynamic) onMessageReceived,
  }) {
    disconnect();
    _groupId = groupId;
    _openSocket(
      groupId: groupId,
      token: token,
      onMessageReceived: onMessageReceived,
    );
  }

  Future<void> _openSocket({
    required String groupId,
    required String token,
    required Function(dynamic) onMessageReceived,
  }) async {
    final resolvedToken = await AuthHeaders.resolve(token);
    if (resolvedToken == null) {
      return;
    }

    stompClient = StompClient(
      config: StompConfig.sockJS(
        url: AppConstants.webSocketUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $resolvedToken'},

        reconnectDelay: const Duration(seconds: 5),

        onConnect: (frame) {
          print("✅ STOMP CONNECTED");
          isConnected = true;

          /// subscribe
          stompClient?.subscribe(
            destination: '/topic/group.$groupId',
            callback: (frame) {
              print("📩 RAW FRAME: ${frame.body}");

              if (frame.body != null) {
                onMessageReceived(jsonDecode(frame.body!));
              }
            },
          );
        },

        onWebSocketError: (error) {
          print("❌ WS ERROR: $error");
        },

        onStompError: (frame) {
          print("❌ STOMP ERROR: ${frame.body}");
        },

        onDisconnect: (_) {
          print("🔌 DISCONNECTED");
          isConnected = false;
        },
      ),
    );

    stompClient?.activate();
  }

  /// ✅ CORRECT SEND METHOD
  void sendMessage({required String groupId, required String text, int? replyToId}) {
    if (!isConnected || stompClient == null || _groupId == null) {
      print("⚠️ NOT CONNECTED YET");
      return;
    }

    final message = {
      "groupId": _groupId,
      "message": text,
      "mediaUrl": null,
      "messageType": "TEXT",
      "uuid": DateTime.now().millisecondsSinceEpoch.toString(),
      "replyToId": replyToId,
    };

    print("🚀 SENDING: $message");

    stompClient?.send(destination: '/app/chat.send', body: jsonEncode(message));
  }

  void disconnect() {
    isConnected = false;
    stompClient?.deactivate();
    stompClient = null;
  }
}
