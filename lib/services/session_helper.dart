import 'package:shared_preferences/shared_preferences.dart';

class SessionHelper {
  static const _keyUsername = 'username'; // email
  static const _keyRole = 'role';
  static const _keyJabatan = 'jabatan';

  // Simpan data user ke shared preferences
  static Future<void> saveUser(String username, String role, String jabatan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyJabatan, jabatan);
  }

  // Ambil username/email saja
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Ambil role saja
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  // Ambil jabatan saja
  static Future<String?> getJabatan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyJabatan);
  }

  // Ambil seluruh data user (misal untuk akun_screen.dart)
  static Future<Map<String, String>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString(_keyUsername) ?? '',
      'role': prefs.getString(_keyRole) ?? '',
      'jabatan': prefs.getString(_keyJabatan) ?? '',
    };
  }

  // Hapus data user (logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyJabatan);
  }

  // Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUsername);
  }
}
