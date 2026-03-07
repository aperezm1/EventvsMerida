import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

class SharedPreferencesService {
  static const String usuarioKey = 'usuario_data';
  static const String autoLoginKey = 'autologin_data';
  static Usuario? usuarioSesionActual;

  // Guardar un usuario
  static Future<void> guardarUsuarioKey(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(usuario.toJson());
    await prefs.setString(usuarioKey, json);
  }

  // Cargar usuario (o null si no hay datos)
  static Future<Usuario?> cargarUsuarioKey() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(usuarioKey);
    if (json == null) return null;
    final Map<String, dynamic> data = jsonDecode(json);
    return Usuario.fromJson(data);
  }

  // Eliminar los datos de usuario (logout)
  static Future<void> borrarUsuarioKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(usuarioKey);
  }

  // Guarda el valor de autoLogin
  static Future<void> guardarAutoLoginKey(bool autoLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(autoLoginKey, autoLogin);
  }

  // Cargar autoLogin (o false si no hay datos)
  static Future<bool> cargarAutoLoginKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(autoLoginKey) ?? false;
  }

  // Eliminar los datos de usuario (logout)
  static Future<void> borrarAutoLoginKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(autoLoginKey);
  }

  static Future<Usuario?> cargarUsuario() async {
    final autoLogin = await SharedPreferencesService.cargarAutoLoginKey();

    if (autoLogin) {
      final usuario = await SharedPreferencesService.cargarUsuarioKey();
      return usuario;
    } else if (usuarioSesionActual != null){
        return usuarioSesionActual;
    } else {
      return null;
    }
  }
}