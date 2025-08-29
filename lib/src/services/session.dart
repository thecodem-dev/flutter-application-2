import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  static const _storage = FlutterSecureStorage();
  static Future<void> saveToken(String token, String role) async {
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'role', value: role);
  }

  static Future<String?> token() => _storage.read(key: 'token');
  static Future<String?> role() => _storage.read(key: 'role');
  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
