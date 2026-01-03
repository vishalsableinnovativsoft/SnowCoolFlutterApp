// lib/services/view_user_api.dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/api_config.dart';
import '../utils/api_utils.dart';

class UserResponse {
  final bool success;
  final String? message;

  const UserResponse({required this.success, this.message});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
    );
  }
}

class ViewUserApi {
  final String baseUrl;

  ViewUserApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // --------------------------------------------------------------
  //  GET  api/v1/settings/users/getAllUsers
  // --------------------------------------------------------------
  Future<List<User>> getUsers() async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/settings/users/getAllUsers');
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ViewUserApi getUsers: GET $url');

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      log('ViewUserApi getUsers: status=${resp.statusCode}');
      log('ViewUserApi getUsers: body=${resp.body}');

      if (resp.statusCode == 200) {
        // The API may return a wrapper like { "data": [...] } or just a plain list.
        // Handle both cases safely.
        final dynamic decoded = jsonDecode(resp.body);

        List<dynamic> userList;
        if (decoded is List) {
          userList = decoded;
        } else if (decoded is Map<String, dynamic> &&
            decoded.containsKey('data')) {
          userList = decoded['data'] as List<dynamic>;
        } else {
          throw Exception('Unexpected response format');
        }

        return userList.map((json) => User.fromJson(json)).toList();
      } else {
        log('ViewUserApi getUsers: failed with status ${resp.statusCode}');
        throw Exception('Failed to load users (status: ${resp.statusCode})');
      }
    } catch (e) {
      log('ViewUserApi getUsers: network error: $e');
      rethrow; // Let UI show error & fallback to demo if needed
    }
  }

  // --------------------------------------------------------------
  // GET api/v1/settings/users/{id}
  // --------------------------------------------------------------
  Future<User?> getUserById(int userId) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/settings/users/$userId');
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ViewUserApi getUserById: GET $url');

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      log('ViewUserApi getUserById: status=${resp.statusCode}');
      log('ViewUserApi getUserById: body=${resp.body}');

      if (resp.statusCode == 200) {
        final dynamic decoded = jsonDecode(resp.body);

        Map<String, dynamic> userJson;
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            userJson = data;
          } else {
            throw Exception('Unexpected format for user data');
          }
        } else if (decoded is Map<String, dynamic>) {
          userJson = decoded;
        } else {
          throw Exception('Unexpected response format');
        }

        return User.fromJson(userJson);
      } else if (resp.statusCode == 404) {
        return null; // Not found
      } else {
        log('ViewUserApi getUserById: failed with status ${resp.statusCode}');
        throw Exception('Failed to load user (status: ${resp.statusCode})');
      }
    } catch (e) {
      log('ViewUserApi getUserById: network error: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------
  //  PUT  api/v1/settings/users/{id}/status
  // --------------------------------------------------------------

  Future<UserResponse> updateUserStatus(String userName, bool isActive) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse(
      '$normalizedBase/api/v1/settings/users/$userName/status?active=$isActive',
    );
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ViewUserApi updateUserStatus: PUT $url');

    try {
      final resp = await http
          .put(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      log('ViewUserApi updateUserStatus: status=${resp.statusCode}');
      log('ViewUserApi updateUserStatus: response=${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return const UserResponse(success: true, message: 'Status updated');
      } else {
        return UserResponse(
          success: false,
          message: resp.body.isNotEmpty ? resp.body : 'Update failed',
        );
      }
    } catch (e) {
      log('ViewUserApi updateUserStatus: error $e');
      return UserResponse(success: false, message: 'Network error');
    }
  }

  // --------------------------------------------------------------
  //  PUT  api/v1/settings/users/{id}
  // --------------------------------------------------------------
  Future<UserResponse> updateUser(
    int userId,
    String username,
    String password,
    String role,
    bool active,
  ) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/settings/users/$userId');
    final headers = ApiUtils.getAuthenticatedHeaders();
    final body = jsonEncode({
      'username': username,
      'password': password,
      'role': role,
      'active': active,
    });

    log('ViewUserApi updateUser: PUT $url');
    log('ViewUserApi updateUser: body=$body');

    try {
      final resp = await http
          .put(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      log('ViewUserApi updateUser: status=${resp.statusCode}');
      log('ViewUserApi updateUser: response=${resp.body}');

      if (resp.statusCode == 200) {
        return UserResponse.fromJson(jsonDecode(resp.body));
      } else {
        return const UserResponse(
          success: false,
          message: 'Failed to update user.',
        );
      }
    } catch (e) {
      log('ViewUserApi updateUser: error $e');
      return UserResponse(success: false, message: 'Network error');
    }
  }

  // --------------------------------------------------------------
  //  DELETE  api/v1/settings/users/{id}
  // --------------------------------------------------------------
  Future<UserResponse> deleteUser(String userId) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/api/v1/settings/users/$userId');
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ViewUserApi deleteUser: DELETE $url');

    try {
      final resp = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      log('ViewUserApi deleteUser: status=${resp.statusCode}');
      log('ViewUserApi deleteUser: response=${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return const UserResponse(success: true, message: 'User deleted');
      } else {
        return const UserResponse(
          success: false,
          message: 'Failed to delete user.',
        );
      }
    } catch (e) {
      log('ViewUserApi deleteUser: error $e');
      return UserResponse(success: false, message: 'Network error');
    }
  }
}
