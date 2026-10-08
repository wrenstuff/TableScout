import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  WebSocketService._();

  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  Stream<dynamic>? _messages;

  Stream<dynamic> get messages {
    final stream = _messages;

    if (stream == null) {
      throw StateError("WebSocket not connected");
    }

    return stream;
  }

  Future<void> connect() async {
    if(_channel != null) return;

    final channel = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:8765'),
    );

    _channel = channel;
    _messages = channel.stream.asBroadcastStream();

    try {
      await channel.ready;
    } catch (_) {
      _channel = null;
      _messages = null;
      rethrow;
    }
  }

  void send(Map<String, dynamic> message) {
    final channel = _channel;

    debugPrint('send() called: $message');

    if (channel == null) {
      throw StateError('WebSocket is not connected.');
    }

    final encodedMessage = jsonEncode(message);
    channel.sink.add(encodedMessage);

    debugPrint('Message queued: $encodedMessage');
  }

  Future<void> disconnect() async {
    final channel = _channel;
    _channel = null;
    _messages = null;

    if (channel != null) {
      await channel.sink.close();
    }
  }
}