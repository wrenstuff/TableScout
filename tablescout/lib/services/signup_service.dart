import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tablescout/app_config.dart';

class SignupService {
  static const String serverUrl = AppConfig.webSocketUrl;

  static Future<Map<String, dynamic>> signup({
    required String username,
    required String storeName,
    required String email,
    required String password,
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
          'type': 'signup',
          'username': username.trim(),
          'store_name': storeName.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      final response = await channel.stream
         .first
        .timeout(const Duration(seconds: 15));

      final data =
         jsonDecode(response as String) as Map<String, dynamic>;

      if (data['success'] == true) {
         return data;
       }

       throw Exception(
        data['error'] ?? "Signup could not be completed.",
       );
    } finally {
      await channel.sink.close();
    }
  }
}