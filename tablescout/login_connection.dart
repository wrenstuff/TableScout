import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> fetchData() async {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator or web
  final response = await http.get(Uri.parse('http://10.0.2'));
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print(data['message']);
  } else {
    throw Exception('Failed to load data');
  }
}
