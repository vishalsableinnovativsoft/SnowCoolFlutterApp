import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';

// secure_storage.dart
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> persistLoginData({
    required String token,
    required int userId,
    required String role,
    Map<String, dynamic>? permissions,
  }) async {
    await _prefs.setString('auth_token', token);
    await _prefs.setInt('user_id', userId);
    await _prefs.setString('user_role', role);
    if (permissions != null) {
      await _prefs.setString('user_permissions', jsonEncode(permissions));
    }

    // Update TokenManager in memory
    TokenManager().login(
      token: token,
      id: userId,
      role: role,
      permissions: permissions,
    );
    // TokenManager().setToken(token);
    // TokenManager().setId(userId);
    // TokenManager().setRole(role);
    // if (permissions != null) TokenManager().setPermissionsFromJson(permissions);
    // Debug-only: log persisted values (token length only, not token itself)
    assert(() {
      debugPrint(
        'SecureStorage: persistLoginData -> id=$userId, role=$role, tokenLen=${token.length}',
      );
      return true;
    }());
  }

  Future<bool> loadSavedLogin() async {
    return _prefs.getBool('isLoggedIn') ?? false;
  }

  Future<String?> getToken() async {
    return _prefs.getString('auth_token');
  }

  bool isTokenExpired(String token) {
    try {
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))),
      );
      final expiry = payload['exp'] as int;
      return DateTime.now().millisecondsSinceEpoch / 1000 > expiry;
    } catch (e) {
      return true; // If decoding fails, assume the token is invalid
    }
  }

  /// Call this once at app startup (in main.dart) to restore login if exists
  Future<bool> tryAutoLogin() async {
    final token = _prefs.getString('auth_token');
    final userId = _prefs.getInt('user_id');
    final role = _prefs.getString('user_role');
    final permissionsJson = _prefs.getString('user_permissions');

    if (token == null || userId == null || role == null) {
      return false; // No saved login
    }

    // Check if token is expired
    if (isTokenExpired(token)) {
      await logout(); // Clear expired data
      return false;
    }

    Map<String, dynamic>? permissions;
    if (permissionsJson != null) {
      try {
        permissions = jsonDecode(permissionsJson) as Map<String, dynamic>;
      } catch (e) {
        permissions = null;
      }
    }

    // RESTORE LOGIN IN MEMORY
    TokenManager().login(
      token: token,
      id: userId,
      role: role,
      permissions: permissions,
    );

    debugPrint('SecureStorage: Auto-login successful → ID=$userId, Role=$role');
    return true;
  }

  /// Updated logout — now properly clears everything
  Future<void> logout() async {
    await _prefs.clear();
    TokenManager()
        .logout(); // This triggers auto-logout timer cancel + clears memory
    debugPrint('SecureStorage: User logged out & data cleared');
  }

  // Add inside SecureStorage class

// Sync versions (no async/await needed in main)
String? getTokenSync() => _prefs.getString('auth_token');
int? getUserIdSync() => _prefs.getInt('user_id');
String? getRoleSync() => _prefs.getString('user_role');
String? getPermissionsJsonSync() => _prefs.getString('user_permissions');

bool isTokenExpiredSync(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    final exp = payload['exp'] as int?;
    if (exp == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
  } catch (e) {
    return true;
  }
}

  //   Future<void> logout(BuildContext context) async {
  //     await _prefs.clear();
  // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
  //     TokenManager().clearToken();
  //   }
}
