
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tablescout/app_config.dart';

class ContactService {
  static const String serverUrl =AppConfig.httpBaseUrl;

  static Future<Map<String, dynamic>> sendContactMessage({
    required String name,
    required String email,
    required String message,
  }) async {
    final url = Uri.parse('$serverUrl/tablescout/pages/contact'
     
    );
      final response = await http.post (
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'message': message.trim(),
        }),
      ).timeout(const Duration(seconds:15));
  
      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception("Invalid response format.");
      }
      if (response.statusCode >= 200 &&
      response.statusCode <300  &&
      data['success'] == true) {
        return data;
    } 
    throw Exception(
      data['message'] ?? "message could not be sent."
    );
    

  }  
}