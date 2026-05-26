import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static const int timeoutSeconds = 30;

  static Future<Map<String, dynamic>?> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('GET Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('API GET Error: $e');
      return null;
    }
  }

  // Fix POST method - return Map instead of accepting it
  static Future<Map<String, dynamic>?> postFormData(String endpoint, Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: data,
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('POST Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('API POST Error: $e');
      return null;
    }
  }
}
