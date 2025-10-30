import 'token_manager.dart';

/// Utility class for common API operations
class ApiUtils {
  /// Get standard headers with authentication if token is available
  static Map<String, String> getAuthenticatedHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add Authorization header if token is available
    final token = TokenManager().getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Check if user is currently authenticated
  static bool isAuthenticated() {
    return TokenManager().isAuthenticated();
  }
}
