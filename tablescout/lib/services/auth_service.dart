import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthService {
  //Local Dev Address
  // CHANGE TO SERVER ADDRESS
  static const String baseURL = 'http://localhost:5000';

  static const Duration requestTimeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final Uri uri = Uri.parse(
      '$baseURL/tablescout/pages/login',
    );

    try {
      final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
          }),
        )
        .timeout(requestTimeout);

      //Deconde the response defensively
      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          "The server returned an invalid response",
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'The server has returned an unexpected response format',
        );
      }

      final data = decoded;

      if (response.statusCode == 200) {
        return data;
      }

      //Keep the status code available for debugging
      throw Exception(
        'Login request failed (${response.statusCode}).',
      );
    } on TimeoutException {
      throw Exception(
        'The server took too long to respond.',
      );
    } on SocketException {
      throw Exception(
        'Could not connect to server. Chek it is running'
      );
    } on FormatException {
      throw Exception(
        'The server returned an invalid response.',
      );
    }
  }

  static Future<Map<String, dynamic>> updateAccount({
    required int userId,
    required String currentPassword,
    required String username,
    required String email,
    required String phoneNumber,
  }) async {
    final Uri uri = Uri.parse(
      '$baseURL/tablescout/pages/update-account',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'currentPassword': currentPassword,
              'username': username.trim(),
              'email': email.trim(),
              'phoneNumber': phoneNumber.trim(),
            }),
          )
          .timeout(requestTimeout);

      // Decode the response defensively.
      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          'The server returned an invalid response.',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'The server returned an unexpected response format.',
        );
      }

      if (response.statusCode == 200) {
        return decoded;
      }

      // Use the error message supplied by Flask, if available.
      final message = decoded['error'];

      if (message is String && message.isNotEmpty) {
        throw Exception(message);
      }

      throw Exception(
        'Account update failed (${response.statusCode}).',
      );
    } on TimeoutException {
      throw Exception(
        'The server took too long to respond.',
      );
    } on SocketException {
      throw Exception(
        'Could not connect to the server. Check that it is running.',
      );
    } on FormatException {
      throw Exception(
        'The server returned an invalid response.',
      );
    }
  }
}