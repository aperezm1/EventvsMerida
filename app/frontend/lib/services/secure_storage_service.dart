import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para manejar el almacenamiento seguro de datos sensibles como tokens,
/// información del usuario y cookies de sesión.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const _refreshTokenKey = 'refresh_token';
  static const String _usuarioKey = 'usuario_data';
  static const String _sessionCookieKey = 'session_cookie';


  static Future<void> guardarRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> cargarRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> borrarRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }


  // ===========================
  // Usuario
  // ===========================

  static Future<void> guardarUsuario(String usuarioJson) async {
    await _storage.write(key: _usuarioKey, value: usuarioJson);
  }

  static Future<String?> cargarUsuario() async {
    return await _storage.read(key: _usuarioKey);
  }

  static Future<void> borrarUsuario() async {
    await _storage.delete(key: _usuarioKey);
  }

  // ===========================
  // Cookie de sesión
  // ===========================

  static Future<void> guardarSessionCookie(String cookie) async {
    await _storage.write(key: _sessionCookieKey, value: cookie);
  }

  static Future<String?> cargarSessionCookie() async {
    return await _storage.read(key: _sessionCookieKey);
  }

  static Future<void> borrarSessionCookie() async {
    await _storage.delete(key: _sessionCookieKey);
  }

  // ===========================
  // Limpieza general de sesión
  // ===========================

  static Future<void> borrarDatosSesion() async {
    await borrarRefreshToken();
    await borrarUsuario();
    await borrarSessionCookie();
  }
}