import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:snow_trading_cool/models/user_model.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

/// Response model used by your backend
class UserResponse {
  final bool success;
  final String? message;

  UserResponse({required this.success, this.message});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
    );
  }
}

class UserApi {
  final String baseUrl;

  UserApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<UserResponse> createOrUpdateUser({
    int? id,
    required String username,
    required String password,
    required String role,
    required bool active,
    required bool canCreateCustomer,
    required bool canManageCustomer,
    required bool canManageGoodsItem,
    required bool canManageChallan,
    required bool canManageProfile,
    required bool canManageSetting,
    required bool canManagePassbook,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/settings/users/create');
    final body = jsonEncode({
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'active': active,
      'canCreateCustomer': canCreateCustomer,
      'canManageCustomer': canManageCustomer,
      'canManageGoodsItem': canManageGoodsItem,
      'canManageChallan': canManageChallan,
      'canManageProfile': canManageProfile,
      'canManageSetting': canManageSetting,
      'canManagePassbook': canManagePassbook,
    });

    log('UserApi createOrUpdateUser: POST $url');
    log('Body: $body');

    final headers = ApiUtils.getAuthenticatedHeaders();
    log('Headers: $headers');

    try {
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      log('Status: ${resp.statusCode}');
      log('Response: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Backend returns full user object or message
        String msg = id == null
            ? 'User created successfully'
            : 'User updated successfully';
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map<String, dynamic>) {
            msg = decoded['message']?.toString() ?? msg;
          }
        } catch (e) {
          log('JSON parse skipped: $e');
        }

        return UserResponse(success: true, message: msg);
      } else {
        return UserResponse(
          success: false,
          message:
              'Failed to ${id == null ? 'create' : 'update'} user (HTTP ${resp.statusCode})',
        );
      }
    } catch (e) {
      log('UserApi createOrUpdateUser: network error: $e');
      return UserResponse(success: false, message: 'Network error: $e');
    }
  }

  /// DELETE /api/v1/settings/users/delete/{id}
  /// Backend returns plain string (e.g. "User deleted") or empty body
  Future<UserResponse> deleteUser(int userId) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/api/v1/settings/users/delete/$userId',
    );

    final headers = ApiUtils.getAuthenticatedHeaders();
    log('UserApi delete: DELETE $url');
    log('Headers: $headers');

    try {
      final resp = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      log('Status: ${resp.statusCode}');
      log('Response: ${resp.body}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        String? message;
        try {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          message = json['message']?.toString();
        } catch (_) {
          if (resp.body.isNotEmpty) {
            message = resp.body.trim();
          }
        }
        return UserResponse(
          success: true,
          message: message ?? 'User deleted successfully',
        );
      } else {
        String? errorMsg;
        try {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          errorMsg = json['message']?.toString() ?? json['error']?.toString();
        } catch (_) {
          errorMsg = resp.body.isNotEmpty ? resp.body : 'Delete failed';
        }
        return UserResponse(
          success: false,
          message: errorMsg ?? 'Failed to delete user',
        );
      }
    } catch (e) {
      log('UserApi delete: network error: $e');
      return UserResponse(success: false, message: 'Network error: $e');
    }
  }

 /// Fetches a single user by ID from the server
/// Returns a [User] object directly (your backend returns the user object, not wrapped)
Future<User> getUserById(int id) async {
  final normalizedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  final String url = '$normalizedBase/api/v1/settings/users/getById/$id';

  log('UserApi getUserById: GET $url');
  log('Token: Bearer ${TokenManager().getToken()}');

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: ApiUtils.getAuthenticatedHeaders(), // Reusing your existing helper
    );

    log('Status: ${response.statusCode}');
    log('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return User.fromJson(json);
    } else if (response.statusCode == 404) {
      throw Exception('User not found with ID: $id');
    } else {
      final String errorMsg = response.body.isNotEmpty
          ? response.body
          : 'HTTP ${response.statusCode}';
      throw Exception('Failed to load user: $errorMsg');
    }
  } catch (e) {
    log('UserApi getUserById error: $e');
    rethrow; // Let the UI show toast and handle gracefully
  }
}

}
