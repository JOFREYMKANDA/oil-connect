import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
