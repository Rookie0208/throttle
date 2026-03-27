import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class ChatSocket {
  late StompClient stompClient;
  bool isConnected = false;

  late String _groupId;

  void connect({
    required String groupId,
    required String token,
    required Function(dynamic) onMessageReceived,
  }) {
    _groupId = groupId;

    stompClient = StompClient(
      config: StompConfig.SockJS(
        url: 'http://localhost:8080/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $token'},

        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},

        reconnectDelay: const Duration(seconds: 5),

        onConnect: (frame) {
          print("✅ STOMP CONNECTED");
          isConnected = true;

          /// subscribe
          stompClient.subscribe(
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

    stompClient.activate();
  }

  /// ✅ CORRECT SEND METHOD
  void sendMessage({required String groupId, required String text}) {
    if (!isConnected) {
      print("⚠️ NOT CONNECTED YET");
      return;
    }

    final message = {
      "groupId": _groupId,
      "message": text,
      "mediaUrl": null,
      "messageType": "TEXT",
      "uuid": DateTime.now().millisecondsSinceEpoch.toString(),
    };

    print("🚀 SENDING: $message");

    stompClient.send(destination: '/app/chat.send', body: jsonEncode(message));
  }

  void disconnect() {
    stompClient.deactivate();
  }
}
