import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  String? _token;
  Timer? _logoutTimer;

  int? _id;
  String? _role;

  // Permission flags
  bool? _canCreateCustomer;
  bool? _canManageCustomer;
  bool? _canManageChallan;
  bool? _canManageGoodsItem;
  bool? _canManageProfile;
  bool? _canManageSetting;
  bool? _canManagePassbook;

  // ========================
  // PUBLIC API - Use this after login!
  // ========================
  void login({
    required String token,
    required int id,
    required String role,
    Map<String, dynamic>? permissions, // optional JSON with bool flags
  }) {
    // 1. Set token with smart expiry handling
    setAccessToken(token);

    // 2. Set user data
    _id = id;
    _role = role;

    // 3. Set permissions if provided
    if (permissions != null) {
      setPermissionsFromJson(permissions);
    }

    log("permission given to user ${permissions.toString()}");
  }

  /// Set token + automatically schedule logout based on JWT `exp`
  void setAccessToken(String token) {
    _token = token;
    _logoutTimer?.cancel();

    final expiryTime = _getTokenExpiryTime(token);
    if (expiryTime == null) {
      print('TokenManager: Could not parse expiry, no auto-logout scheduled');
      return;
    }

    final now = DateTime.now();
    final duration = expiryTime.difference(now);

    if (duration.isNegative) {
      logout();
    } else {
      _logoutTimer = Timer(duration, () {
        print('TokenManager: Token expired, auto-logout triggered');
        logout();
      });
      print('TokenManager: Auto-logout scheduled at $expiryTime');
    }
  }

  DateTime? _getTokenExpiryTime(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      if (exp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch((exp as num).toInt() * 1000);
    } catch (e) {
      print('TokenManager: Failed to parse JWT expiry: $e');
      return null;
    }
  }

  /// Perform logout (clears everything + you can navigate here)
  void logout() {
    _token = null;
    _id = null;
    _role = null;

    _canCreateCustomer = null;
    _canManageChallan = null;
    _canManageGoodsItem = null;
    _canManageProfile = null;
    _canManageSetting = null;
    _canManagePassbook = null;
    _canManageCustomer = null;

    _logoutTimer?.cancel();
    _logoutTimer = null;

    print('TokenManager: User logged out');

    // Optional: Navigate to login screen (requires context!)
    // You can make this customizable via a callback:
    _onLogoutCallback?.call();
  }

  // Optional: Allow app to react to logout (e.g. navigate to login)
  VoidCallback? _onLogoutCallback;
  void setOnLogoutListener(VoidCallback callback) {
    _onLogoutCallback = callback;
  }

  // ========================
  // Getters
  // ========================
  String? getToken() => _token;
  int? getId() => _id;
  String? getRole() => _role;

  bool get isAuthenticated => _token != null && !_isTokenExpired(_token!);

  bool _isTokenExpired(String token) {
    final expiry = _getTokenExpiryTime(token);
    return expiry == null || DateTime.now().isAfter(expiry);
  }

  // Permission getters (safe defaults = false)
  bool get canManageCustomer => _canManageCustomer ?? false;
  bool get canCreateCustomer => _canCreateCustomer ?? false;
  bool get canManageChallan => _canManageChallan ?? false;
  bool get canManageGoodsItem => _canManageGoodsItem ?? false;
  bool get canManageProfile => _canManageProfile ?? false;
  bool get canManageSetting => _canManageSetting ?? false;
  bool get canManagePassbook => _canManagePassbook ?? false;

  void setPermissionsFromJson(Map<String, dynamic> json) {
    _canManageCustomer = json['canManageCustomer'] as bool?;
    _canCreateCustomer = json['canCreateCustomer'] as bool?;
    _canManageChallan = json['canManageChallan'] as bool?;
    _canManageGoodsItem = json['canManageGoodsItem'] as bool?;
    _canManageProfile = json['canManageProfile'] as bool?;
    _canManageSetting = json['canManageSetting'] as bool?;
    _canManagePassbook = json['canManagePassbook'] as bool?;
  }

  /// Fully clear all data (e.g. on manual logout)
  void clearAll() => logout();
}
