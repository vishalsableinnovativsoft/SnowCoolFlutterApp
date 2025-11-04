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

  Future<List<User>> getUsers() async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/users');
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ViewUserApi getUsers: GET $url');

    try {
      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      log('ViewUserApi getUsers: status=${resp.statusCode}');

      if (resp.statusCode == 200) {
        final List<dynamic> jsonResp = jsonDecode(resp.body);
        return jsonResp.map((json) => User.fromJson(json)).toList();
      } else {
        log('ViewUserApi getUsers: failed with status ${resp.statusCode}');
        throw Exception('Failed to load users');
      }
    } catch (e) {
      log('ViewUserApi getUsers: network error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<UserResponse> updateUserStatus(String userId, bool isActive) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/user/$userId/status');
    final headers = ApiUtils.getAuthenticatedHeaders();
    final body = jsonEncode({'active': isActive});

    log('ViewUserApi updateUserStatus: PUT $url');
    log('ViewUserApi updateUserStatus: body=$body');

    try {
      final resp = await http
          .put(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      log('ViewUserApi updateUserStatus: status=${resp.statusCode}');
      log('ViewUserApi updateUserStatus: response=${resp.body}');

      if (resp.statusCode == 200) {
        return UserResponse.fromJson(jsonDecode(resp.body));
      } else {
        return UserResponse(
          success: false,
          message: 'Failed to update user status. Please try again.',
        );
      }
    } catch (e) {
      log('ViewUserApi updateUserStatus: network error: $e');
      return UserResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<UserResponse> updateUser(
    String userId,
    String username,
    String password,
    String role,
    bool active,
  ) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/user/$userId');
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
        return UserResponse(
          success: false,
          message: 'Failed to update user. Please try again.',
        );
      }
    } catch (e) {
      log('ViewUserApi updateUser: network error: $e');
      return UserResponse(success: false, message: 'Network error: $e');
    }
  }

  Future<UserResponse> deleteUser(String userId) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/user/$userId');
    final headers = ApiUtils.getAuthenticatedHeaders();

    log('ViewUserApi deleteUser: DELETE $url');

    try {
      final resp = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      log('ViewUserApi deleteUser: status=${resp.statusCode}');
      log('ViewUserApi deleteUser: response=${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return const UserResponse(success: true, message: 'User deleted successfully');
      } else {
        return UserResponse(
          success: false,
          message: 'Failed to delete user. Please try again.',
        );
      }
    } catch (e) {
      log('ViewUserApi deleteUser: network error: $e');
      return UserResponse(success: false, message: 'Network error: $e');
    }
  }
}