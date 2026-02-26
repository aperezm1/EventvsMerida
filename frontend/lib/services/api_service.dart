import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://eventvsmerida.onrender.com/api";

  static Future<String> registrar(Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse("$baseUrl/usuarios/add");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 10));

      switch (response.statusCode) {
        case 201:
          return "Registro exitoso";
        case 400:
          return "Datos inválidos, revisa los campos";
        case 409:
          return "El correo ya está registrado";
        case 500:
          return "Error interno del servidor";
        default:
          return "Error inesperado: ${response.statusCode}";
      }
    } on TimeoutException {
      return "El servidor tarda demasiado en responder";
    } on SocketException {
      return "No hay conexión a internet";
    } catch (e) {
      return "Error desconocido";
    }
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

  static Future<List<dynamic>> obtenerEventos() async {
    final respuesta = await http.get(Uri.parse("$baseUrl/eventos/all"));

    if (respuesta.statusCode == 200) {
      return jsonDecode(respuesta.body);
    } else {
      throw Exception('Error al cargar los usuarios');
    }
  }
}
