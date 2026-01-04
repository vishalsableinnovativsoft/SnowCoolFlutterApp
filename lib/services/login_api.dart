
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/token_manager.dart';

/// Structured response from the login API
class LoginResponse {
  final bool success;
  final String? message;
  final String? field;
  final String? token;
  final int? id;
  final String? role;

  // Permission flags from backend
  final bool? canCreateCustomer;
  final bool? canManageCustomer;
  final bool? canManageChallan;
  final bool? canManageGoodsItem;
  final bool? canManageProfile;
  final bool? canManageSetting;
  final bool? canManagePassbook;

  LoginResponse({
    required this.success,
    this.message,
    this.field,
    this.token,
    this.id,
    this.role,
    this.canManageCustomer,
    this.canCreateCustomer,
    this.canManageChallan,
    this.canManageGoodsItem,
    this.canManageProfile,
    this.canManageSetting,
    this.canManagePassbook,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true || json['token'] != null,
      message: json['message']?.toString(),
      field: json['field']?.toString(),
      token: json['token']?.toString(),
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      role: json['role']?.toString(),
      canManageCustomer: json['canManageCustomer'] as bool?,
      canCreateCustomer: json['canCreateCustomer'] as bool?,
      canManageChallan: json['canManageChallan'] as bool?,
      canManageGoodsItem: json['canManageGoodsItem'] as bool?,
      canManageProfile: json['canManageProfile'] as bool?,
      canManageSetting: json['canManageSetting'] as bool?,
      canManagePassbook: json['canManagePassbook'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'id': id,
        'role': role,
        'canCreateCustomer': canCreateCustomer,
        'canManageCustomer' : canManageCustomer,
        'canManageChallan': canManageChallan,
        'canManageGoodsItem': canManageGoodsItem,
        'canManageProfile': canManageProfile,
        'canManageSetting': canManageSetting,
        'canManagePassbook': canManagePassbook,
      };
}

class LoginApi {
  final String baseUrl;

  LoginApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<LoginResponse> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/login');

    // http://154.61.76.108:8081/api/v1/auth/login
    final body = jsonEncode({'username': username, 'password': password});

    debugPrint('LoginApi: POST $uri');

    try {
      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 12));

      debugPrint('LoginApi: ${resp.statusCode} → ${resp.body}');

      if (resp.statusCode == 200) {
        final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
        final response = LoginResponse.fromJson(jsonMap);

        if (response.token != null && response.id != null) {
          // ONE AND ONLY PLACE WE UPDATE TOKENMANAGER → CORRECT WAY
          TokenManager().login(
            token: response.token!,
            id: response.id!,
            role: response.role ?? 'USER',
            permissions: jsonMap, // pass full JSON → extracts all can* flags
          );

          debugPrint('TokenManager: Login successful → ID=${response.id}, Role=${response.role}');
        }

        return response;
      }

      // Handle error responses
      try {
        final errorJson = jsonDecode(resp.body) as Map<String, dynamic>;
        return LoginResponse.fromJson(errorJson);
      } catch (_) {
        return LoginResponse(
          success: false,
          message: resp.statusCode == 401 || resp.statusCode == 400
              ? 'Incorrect username or password'
              : 'Server error (${resp.statusCode})',
        );
      }
    } on TimeoutException {
      return LoginResponse(success: false, message: 'Connection timeout');
    } catch (e) {
      debugPrint('LoginApi error: $e');
      return LoginResponse(success: false, message: 'Network error');
    }
  }
}