import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

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

  Future<UserResponse> updateUser(
    String userId,
    {
    required String username,
    required String password,
    required String role,
    required bool active,
    required bool canCreateCustomer,
    required bool canManageGoods,
    required bool canManageChallans,
    required bool canManageProfiles,
    required bool canManageSettings,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/user/$userId'); // Assuming endpoint
    final body = jsonEncode({
      'username': username,
      'password': password,
      'role': role,
      'active': active,
      'canCreateCustomer': canCreateCustomer,
      'canManageGoods': canManageGoods,
      'canManageChallans': canManageChallans,
      'canManageProfiles': canManageProfiles,
      'canManageSettings': canManageSettings,
    });

    log('UserApi update: PUT $url');
    log('UserApi update: body=$body');

    // Token internal from TokenManager
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('UserApi update: headers=$headers');

    try {
      final resp = await http
          .put(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      log('UserApi update: status=${resp.statusCode}');
      log('UserApi update: response=${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          return UserResponse.fromJson(jsonResp);
        } catch (e) {
          log('UserApi update: failed to decode JSON: $e');
          return UserResponse(
            success: false,
            message: 'Invalid server response',
          );
        }
      } else {
        // Similar error handling as profile_api
        return UserResponse(
          success: false,
          message: 'Failed to update user. Please try again.',
        );
      }
    } catch (e) {
      log('UserApi update: network error: $e');
      return UserResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<UserResponse> createUser({
    required String username,
    required String password,
    required String role,
    required bool active,
    required bool canCreateCustomer,
    required bool canManageGoods,
    required bool canManageChallans,
    required bool canManageProfiles,
    required bool canManageSettings,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/user/create'); // Assuming endpoint
    final body = jsonEncode({
      'username': username,
      'password': password,
      'role': role,
      'active': active,
      'canCreateCustomer': canCreateCustomer,
      'canManageGoods': canManageGoods,
      'canManageChallans': canManageChallans,
      'canManageProfiles': canManageProfiles,
      'canManageSettings': canManageSettings,
    });

    log('UserApi create: POST $url');
    log('UserApi create: body=$body');

    // Token internal from TokenManager
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('UserApi create: headers=$headers');

    try {
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      log('UserApi create: status=${resp.statusCode}');
      log('UserApi create: response=${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
          return UserResponse.fromJson(jsonResp);
        } catch (e) {
          log('UserApi create: failed to decode JSON: $e');
          return UserResponse(
            success: false,
            message: 'Invalid server response',
          );
        }
      } else {
        // Similar error handling as profile_api
        return UserResponse(
          success: false,
          message: 'Failed to create user. Please try again.',
        );
      }
    } catch (e) {
      log('UserApi create: network error: $e');
      return UserResponse(success: false, message: 'Network error: $e');
    }
  }
}