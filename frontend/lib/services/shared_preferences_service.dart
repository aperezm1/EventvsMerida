import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

class SharedPreferencesService {
  static const String usuarioKey = 'usuario_data';

  // Guardar un usuario
  static Future<void> guardarUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(usuario.toJson());
    await prefs.setString(usuarioKey, json);
  }

  // Cargar usuario (o null si no hay datos)
  static Future<Usuario?> cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(usuarioKey);
    if (json == null) return null;
    final Map<String, dynamic> data = jsonDecode(json);
    return Usuario.fromJson(data);
  }

  // Eliminar los datos de usuario (logout)
  static Future<void> borrarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(usuarioKey);
  }
}