import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:throttle_ui/core/constants/app_constants.dart';
import 'package:throttle_ui/core/services/logger_service.dart';

class RideRealtimeService {
  StompClient? _client;

  void connect({
    required String token,
    required String rideUuid,
    required VoidCallback onRideUpdated,
  }) {
    disconnect();

    final socketUrl = AppConstants.baseUrl
        .replaceAll('http://', 'ws://')
        .replaceAll('https://', 'wss://')
        .replaceAll('/api/v1', '/ws-friends');

    _client = StompClient(
      config: StompConfig.sockJS(
        url: socketUrl.replaceFirst('ws://', 'http://').replaceFirst(
          'wss://',
          'https://',
        ),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (frame) {
          _client?.subscribe(
            destination: '/topic/rides/$rideUuid',
            callback: (frame) {
              final body = frame.body;
              if (body == null || body.isEmpty) {
                return;
              }

              try {
                final decoded = jsonDecode(body);
                if (decoded is Map) {
                  onRideUpdated();
                }
              } catch (error, stackTrace) {
                Logger.error(
                  'Failed to decode ride websocket event',
                  error,
                  stackTrace,
                );
              }
            },
          );
        },
        onWebSocketError: (dynamic error) {
          Logger.warn('Ride websocket error: $error');
        },
        onStompError: (StompFrame frame) {
          Logger.warn('Ride STOMP error: ${frame.body}');
        },
      ),
    );

    _client?.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }
}
