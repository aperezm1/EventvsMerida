import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const _refreshTokenKey = 'refresh_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> guardarRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> cargarRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> borrarRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }
}

