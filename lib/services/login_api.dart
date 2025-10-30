import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

/// Structured response from the login API.
class LoginResponse {
  final bool success;
  final String? message; // human readable message
  final String? field; // 'username' | 'password' | null
  final String? token;

  LoginResponse({required this.success, this.message, this.field, this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true || json['token'] != null,
      message: json['message']?.toString(),
      field: json['field']?.toString(),
      token: json['token']?.toString(),
    );
  }
}

/// Simple login API wrapper.
class LoginApi {
  final String baseUrl;

  LoginApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Sends username and password to backend and returns a [LoginResponse].
  /// The backend is expected to return JSON like:
  /// { "success": false, "message": "Invalid username", "field": "username" }
  Future<LoginResponse> login(String username, String password) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/v1/auth/login');
    final body = jsonEncode({'username': username, 'password': password});

    // Debug prints (ok during development)
    print('LoginApi: POST $uri');
    print('LoginApi: body=$body');

    try {
      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));

      print('LoginApi: status=${resp.statusCode}');
      print('LoginApi: response=${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonResp =
              jsonDecode(resp.body) as Map<String, dynamic>;
          return LoginResponse.fromJson(jsonResp);
        } catch (e) {
          print('LoginApi: failed to decode JSON: $e');
          return LoginResponse(
            success: false,
            message: 'Invalid server response',
          );
        }
      } else {
        // Handle authentication errors with proper user-friendly messages
        if (resp.statusCode == 400 || resp.statusCode == 401) {
          // Try to parse error message from body first
          try {
            final Map<String, dynamic> jsonResp =
                jsonDecode(resp.body) as Map<String, dynamic>;
            final response = LoginResponse.fromJson(jsonResp);
            // If no specific message, provide default incorrect credentials message
            return LoginResponse(
              success: false,
              message:
                  response.message ??
                  'Incorrect username or password. Please check your credentials and try again.',
              field: response.field,
            );
          } catch (_) {
            // If can't parse response, return default authentication error
            return LoginResponse(
              success: false,
              message:
                  'Incorrect username or password. Please check your credentials and try again.',
            );
          }
        } else {
          // For other status codes, try to parse error or show generic message
          try {
            final Map<String, dynamic> jsonResp =
                jsonDecode(resp.body) as Map<String, dynamic>;
            return LoginResponse.fromJson(jsonResp);
          } catch (_) {
            return LoginResponse(
              success: false,
              message: 'Unable to connect to server. Please try again later.',
            );
          }
        }
      }
    } on TimeoutException catch (e) {
      print('LoginApi: network error: $e');
      return LoginResponse(success: false, message: 'Network error: Timeout');
    } catch (e) {
      print('LoginApi: network error: $e');
      return LoginResponse(success: false, message: 'Network error: $e');
    }
  }
}
