import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://eventvsmerida.onrender.com/api";

  static Future<void> registrar(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/usuarios/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );

    print(response.statusCode);
    print(response.body);
  }

  static Future<String> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/usuarios/login");
    final respuesta = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (respuesta.statusCode == 200) {
      return "Login exitoso";
    } else if (respuesta.statusCode == 404 || respuesta.statusCode == 400) {
      return "Credenciales inválidas";
    } else {
      return "Error en el servidor: ${respuesta.statusCode}";
    }
  }
}