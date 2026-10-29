import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tablescout/app_config.dart';

class ContactService {
  static const String serverUrl =AppConfig.webSocketUrl;

  static Future<Map<String, dynamic>> sendContactMessage({
    required String name,
    required String email,
    required String message,
  }) async {
    final channel = WebSocketChannel.connect(
      Uri.parse(serverUrl),
    );

    try {
      await channel.ready.timeout(
        const Duration(seconds: 10),
      );

      channel.sink.add(
        jsonEncode({
          'type': 'contact',
          'name': name.trim(),
          'email': email.trim(),
          'message': message.trim(),
        }),
      );
  
      final response = await channel.stream.first.timeout(const Duration(seconds: 15));

      final data = jsonDecode(response as String); 

      if (data is! Map<String, dynamic>) {
        throw Exception("Invalid response format.");
      }
      if (data['success'] == true) {
        return data;
      }
      throw Exception(
        data['error'] ?? "Message could not be sent.",
      );
    } finally {
      await channel.sink.close();
    }

  }  
}