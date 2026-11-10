import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  WebSocketService._();

  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  Stream<dynamic>? _messages;
  bool _authenticated = false;

  bool get isAuthenticated => _authenticated;

  Stream<dynamic> get messages {
    final stream = _messages;

    if (stream == null) {
      throw StateError("WebSocket not connected");
    }

    return stream;
  }

  Future<void> connect({required String token}) async {
    if (token.isEmpty) {
      throw ArgumentError("JWT is required.");
    }

    if(_channel != null) {
      debugPrint('Reusing existing WebSocket channel.');
      return;
    } 

    await disconnect();

    debugPrint('Opening WebSocket: ws://127.0.0.1:8765');

    final channel = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:8765'),
    );

    _channel = channel;
    _messages = channel.stream.asBroadcastStream();

    try {
      await channel.ready;
      debugPrint('WebSocket handshake completed');

      final completer = Completer<bool>();

      final subscription = _messages!.listen(
        (message) {
          try {
            final response = jsonDecode(message.toString());

            if (response is Map && response["type"] == 'verified_token') {
              if (!completer.isCompleted) {
                completer.complete(response['valid'] == true);
              }
            }
          } catch (error) {
            debugPrint('Authentication response error: $error');
          }          
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      channel.sink.add(jsonEncode({
        'type': "token_verify",
        "token": token,
      }));

      debugPrint('JWT verification request sent.');

      bool valid;

      try {
        valid = await completer.future.timeout(
          const Duration(seconds: 10),
        );
      } finally {
        await subscription.cancel();
      }

      if (!valid) {
        throw StateError(
          'WebSocket authentication failed. Please log in again.',
        );
      }

      _authenticated = true;
      debugPrint('WebSocket authentication successful.');

    } catch (error) {
      await disconnect();
      debugPrint('WebSocket connection failed: $error');
      rethrow;
    }
  }

  Future<void> reconnect({required String token}) async {
    await disconnect();

    await connect(token: token);
  }

  void send(Map<String, dynamic> message) {
    final channel = _channel;

    if (channel == null) {
      throw StateError('WebSocket is not connected.');
    }

    if (!_authenticated && message["type"] != "token_verify") {
      throw StateError('WebSocket is not authenticated');
    }
    
    debugPrint('send() called: $message');

    final encodedMessage = jsonEncode(message);
    channel.sink.add(encodedMessage);

    debugPrint('Message queued: $encodedMessage');
  }

  Future<void> disconnect() async {
    final channel = _channel;
    _channel = null;
    _messages = null;
    _authenticated = false;

    if (channel != null) {
      await channel.sink.close();
    }
  }
}