import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class Logger {
  static String _getFileAndLine(StackTrace stackTrace) {
    try {
      final frames = stackTrace.toString().split('\n');
      // The first frame is this method, the second is the Logger.info/error/warn method
      // The third frame (index 2) is the actual caller we want
      if (frames.length > 2) {
        final callerFrame = frames[2];
        // Match standard format: "at Function.name (file:///path/to/file.dart:line:column)"
        // Or condensed format: "#2      Function.name (package:app/file.dart:line:column)"
        final RegExp regex = RegExp(r'\((.*?:\d+:\d+)\)');
        final match = regex.firstMatch(callerFrame);
        if (match != null) {
          final fullPath = match.group(1)!;
          // Extract just the filename and line number to keep it clean
          final parts = fullPath.split(':');
          if (parts.length >= 2) {
            String fileName = parts[0].split('/').last;
            // Handle package: URIs
            if (parts.length >= 3 && parts[1].split('/').length > 1) {
              fileName = parts[1].split('/').last;
              return "($fileName:${parts[2]})";
            }
            if (parts.length >= 3) {
              return "($fileName:${parts[1]})";
            }
            return "($fileName)";
          }
          return "($fullPath)";
        }
      }
    } catch (_) {
      // Fallback
    }
    return "";
  }

  static Future<void> info(String message) async {
    final callerInfo = _getFileAndLine(StackTrace.current);
    await _sendToServer('INFO', '$callerInfo $message');
  }

  static Future<void> error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) async {
    final callerInfo = _getFileAndLine(StackTrace.current);
    final fullMessage = error != null
        ? "$callerInfo $message | Error: $error | Stack: $stackTrace"
        : "$callerInfo $message";
    await _sendToServer('ERROR', fullMessage);
  }

  static Future<void> warn(String message) async {
    final callerInfo = _getFileAndLine(StackTrace.current);
    await _sendToServer('WARN', '$callerInfo $message');
  }

  static Future<void> _sendToServer(String level, String message) async {
    try {
      final url = Uri.parse("${AppConstants.baseUrl}/logs");
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"level": level, "message": message}),
      );
    } catch (e) {
      // Don't crash the app if the log server is unreachable
      if (kDebugMode) {
        print('[LOGGER ERROR] Failed to send log to server: $e');
      }
    }
  }
}
