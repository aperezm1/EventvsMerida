import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://10.0.2.2:8080/api/usuarios";

  static Future<void> registrar(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );

    print(response.statusCode);
    print(response.body);
  }
}