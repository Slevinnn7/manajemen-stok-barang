import 'package:shared_preferences/shared_preferences.dart';

class SessionHelper {
  static const _keyUsername = 'username'; // email / UID
  static const _keyRole = 'role';
  static const _keyJabatan = 'jabatan';

  /// ✅ Simpan data user setelah login
  static Future<void> saveUser({
    required String username,
    required String role,
    required String jabatan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyJabatan, jabatan);
  }

  /// ✅ Ambil username/email
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  /// ✅ Ambil role user
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  /// ✅ Ambil jabatan user
  static Future<String?> getJabatan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyJabatan);
  }

  /// ✅ Ambil seluruh data user
  static Future<Map<String, String>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_keyUsername) ?? '',
      'role': prefs.getString(_keyRole) ?? '',
      'jabatan': prefs.getString(_keyJabatan) ?? '',
    };
  }

  /// Hapus data user (logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyJabatan);
  }

  /// Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername);
    final role = prefs.getString(_keyRole);
    return username != null && role != null; // minimal ada username & role
  }
}
