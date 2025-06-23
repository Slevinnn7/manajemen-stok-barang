import 'package:shared_preferences/shared_preferences.dart';

class SessionHelper {
  static const _keyUsername = 'username';
  static const _keyRole = 'role';

  // Simpan data user ke shared preferences
  static Future<void> saveUser(String username, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyRole, role);
  }

  // Ambil username saja
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Ambil role saja
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  // Ambil seluruh data user (digunakan untuk akun_screen.dart)
  static Future<Map<String, String>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername) ?? '';
    final role = prefs.getString(_keyRole) ?? '';
    return {
      'uid': username, // uid = username yang disimpan saat login
      'role': role,
    };
  }

  // Hapus data user (logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
  }

  // Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUsername);
  }
}
