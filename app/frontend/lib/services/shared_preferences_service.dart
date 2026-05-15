import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import 'secure_storage_service.dart';

/// Servicio para gestionar la sesión del usuario y otras preferencias
/// utilizando SharedPreferences.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
class SharedPreferencesService {
  SharedPreferencesService._();

  static const String _usuarioKey = 'usuario_data';
  static const String _autoLoginKey = 'autologin_data';
  static const String _tutorialKey = 'tutorial_data';

  // Sesión en memoria para la ejecución actual de la app.
  static Usuario? usuarioSesionActual;

  static final ValueNotifier<Usuario?> usuarioNotifier =
  ValueNotifier<Usuario?>(null);

  static Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  static Future<bool> getAutoLogin() async {
    final prefs = await _prefs;
    return prefs.getBool(_autoLoginKey) ?? false;
  }

  // ===========================
  // API principal de sesión
  // ===========================

  static Future<void> iniciarSesion({
    required Usuario usuario,
    required bool autoLogin,
  }) async {
    usuarioSesionActual = usuario;
    usuarioNotifier.value = usuario;

    final prefs = await _prefs;
    await prefs.setBool(_autoLoginKey, autoLogin);

    if (autoLogin) {
      await SecureStorageService.guardarUsuario(
        jsonEncode(usuario.toJson()),
      );
    } else {
      await SecureStorageService.borrarUsuario();
      await prefs.remove(_usuarioKey);
    }
  }

  static Future<Usuario?> cargarUsuario() async {
    final prefs = await _prefs;
    final autoLogin = prefs.getBool(_autoLoginKey) ?? false;

    if (!autoLogin) {
      return usuarioSesionActual;
    }

    return await _cargarUsuarioPersistido(prefs);
  }

  static Future<void> cerrarSesion() async {
    usuarioSesionActual = null;
    usuarioNotifier.value = null;

    final prefs = await _prefs;

    await prefs.remove(_autoLoginKey);

    await SecureStorageService.borrarUsuario();
    await SecureStorageService.borrarSessionCookie();
    await SecureStorageService.borrarRefreshToken();
  }

  // ===========================
  // Cookie de sesión
  // ===========================

  static Future<void> guardarSessionCookie(String cookie) async {
    await SecureStorageService.guardarSessionCookie(cookie);
  }

  static Future<String?> cargarSessionCookie() async {
    final cookieSegura = await SecureStorageService.cargarSessionCookie();

    if (cookieSegura != null && cookieSegura.isNotEmpty) {
      return cookieSegura;
    }
    return null;
  }

  // ===========================
  // Internos
  // ===========================

  static Future<Usuario?> _cargarUsuarioPersistido(
      SharedPreferences prefs,
      ) async {
    String? usuarioJson = await SecureStorageService.cargarUsuario();

    if (usuarioJson == null || usuarioJson.isEmpty) {
      await prefs.remove(_autoLoginKey);
      await SecureStorageService.borrarUsuario();
      return null;
    }

    try {
      final data = jsonDecode(usuarioJson) as Map<String, dynamic>;
      final usuario = Usuario.fromJson(data);

      usuarioSesionActual = usuario;
      usuarioNotifier.value = usuario;

      return usuario;
    } catch (_) {
      await prefs.remove(_autoLoginKey);
      await prefs.remove(_usuarioKey);
      await SecureStorageService.borrarUsuario();
      return null;
    }
  }

  // =============================
  // Comprobaciones carga tutorial
  // =============================

  static Future<bool> cargarTutorial() async {
    final prefs = await _prefs;
    return prefs.getBool(_tutorialKey) ?? true;
  }

  static Future<void> finalizarTurorial() async {
    final prefs = await _prefs;
    await prefs.setBool(_tutorialKey, false);
  }

  static Future<void> resetearTutorial() async {
    final prefs = await _prefs;
    await prefs.setBool(_tutorialKey, true);
  }
}