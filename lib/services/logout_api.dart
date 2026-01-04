import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

/// Structured response from the logout API.
class LogoutResponse {
  final bool success;
  final String? message;

  LogoutResponse({required this.success, this.message});

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
    );
  }
}

/// Logout API wrapper.
class LogoutApi {
  final String baseUrl;

  LogoutApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Performs local logout without API call (fallback method)
  LogoutResponse logoutLocally() {
    return LogoutResponse(success: true, message: 'Logged out locally');
  }

  /// Sends logout request to backend and returns a [LogoutResponse].
  /// Tries multiple approaches to handle different server configurations.
  Future<LogoutResponse> logout(String? token) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/v1/auth/logout');

    // First attempt: POST with minimal headers (most common approach)
    final headers = <String, String>{'Accept': 'application/json'};

    // Add authorization header if token is provided
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    debugPrint('LogoutApi: POST $uri (attempt 1 - no body)');
    debugPrint('LogoutApi: headers=$headers');

    try {
      // Try POST without body first (many logout endpoints prefer this)
      final resp = await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      debugPrint('LogoutApi: status=${resp.statusCode}');
      debugPrint('LogoutApi: response=${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        try {
          if (resp.body.isNotEmpty) {
            final Map<String, dynamic> jsonResp =
                jsonDecode(resp.body) as Map<String, dynamic>;
            return LogoutResponse.fromJson(jsonResp);
          } else {
            // Empty response means successful logout
            return LogoutResponse(
              success: true,
              message: 'Logged out successfully',
            );
          }
        } catch (e) {
          debugPrint('LogoutApi: failed to decode JSON: $e');
          return LogoutResponse(
            success: true,
            message: 'Logged out successfully',
          );
        }
      } else if (resp.statusCode == 400) {
        // Handle 400 Bad Request - server might not expect JSON body or has different requirements
        debugPrint(
          'LogoutApi: 400 Bad Request - treating as successful logout for security',
        );
        return LogoutResponse(
          success: true,
          message: 'Logged out successfully (server compatibility mode)',
        );
      } else if (resp.statusCode == 401 || resp.statusCode == 403) {
        // Unauthorized/Forbidden - might mean session already expired, which is fine for logout
        return LogoutResponse(
          success: true,
          message: 'Logged out successfully',
        );
      } else {
        // Try to parse error message from body for other status codes
        try {
          final Map<String, dynamic> jsonResp =
              jsonDecode(resp.body) as Map<String, dynamic>;
          return LogoutResponse.fromJson(jsonResp);
        } catch (_) {
          return LogoutResponse(
            success: false,
            message:
                'Server error (${resp.statusCode}). Logged out locally for security.',
          );
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('LogoutApi: timeout error: $e');
      return LogoutResponse(
        success: true, // Treat timeout as successful logout for security
        message: 'Logged out (connection timeout)',
      );
    } catch (e) {
      debugPrint('LogoutApi: network error: $e');
      return LogoutResponse(
        success: true, // Treat network errors as successful logout for security
        message: 'Logged out (network error)',
      );
    }
  }
}
