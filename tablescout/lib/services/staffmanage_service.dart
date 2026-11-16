import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tablescout/services/auth_service.dart';


class StaffService {
  static const Duration requestTimeout = Duration(seconds: 15);

  static Future<List<Map<String, dynamic>>> getStaff({
    required String token,
  }) async {
    final Uri uri = Uri.parse(
      '${AuthService.baseURL}/tablescout/pages/staff_management',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(requestTimeout);
      debugPrint('STAFF URL: $uri');
      debugPrint('STAFF STATUS: ${response.statusCode}');
      debugPrint('STAFF BODY: ${response.body}');
      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception('The server returned an invalid response.');
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected server response.');
      }

      if (response.statusCode == 200) {
        final staff = decoded['staff'];

        if (staff is! List) {
          throw Exception('Invalid staff data received.');
        }

        return staff
            .whereType<Map>()
            .map((member) => Map<String, dynamic>.from(member))
            .toList();
      }

      final message = decoded['error'];

      if (message is String && message.isNotEmpty) {
        throw Exception(message);
      }

      throw Exception(
        'Unable to retrieve staff (${response.statusCode}).',
      );
    } on TimeoutException {
      throw Exception('The server took too long to respond.');
    } on SocketException {
      throw Exception('Could not connect to the server.');
    }
  }

  static Future<void> updateStaff({
    required String token,
    required int staffId,
    required String username,
    required String email,
    required String role,
  }) async {
    final Uri uri = Uri.parse(
      '${AuthService.baseURL}/tablescout/pages/staff_management/$staffId'
    );

    try {
      final response = await http
        .put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'username': username,
            'email': email,
            'role': role,
          }),
        )
        .timeout(requestTimeout);
      debugPrint('UPDATE STAFF STATUS: ${response.statusCode}');
      debugPrint('UPDATE STAFF BODY: ${response.body}');

      dynamic decoded;

      try{
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception('The server returned an invalid response');
      }
      if (decoded is! Map <String, dynamic>){
        throw Exception('Unexpected server response');
      }
      if (response.statusCode == 200){
        return;
      }
      final message = decoded['error'];

      if (message is String && message.isNotEmpty){
        throw Exception(message);
      }
      throw Exception('unable to update staff member.');
    } on TimeoutException{
      throw Exception('Server took too long sorry.');
    }on SocketException {
      throw Exception('Could not connect to the server.');
    }
  }
}
