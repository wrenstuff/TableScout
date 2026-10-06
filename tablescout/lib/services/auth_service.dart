import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // CHANGE TO SERVER ADDRESS
  static const String baseURL = 'http://localhost:5000';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseURL/tablescout/pages/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['error'] ?? 'Login failed');
  }
}