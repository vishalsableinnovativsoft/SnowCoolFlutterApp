// import 'token_manager.dart';

// /// Utility class for common API operations
// class ApiUtils {
//   /// Get standard headers with authentication if token is available
//   static Map<String, String> getAuthenticatedHeaders() {
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//     };

//     // Add Authorization header if token is available
//     final token = TokenManager().getToken();
//     if (token != null && token.isNotEmpty) {
//       headers['Authorization'] = 'Bearer $token';
//     }
//     // Debug-only: log whether Authorization header exists and show token length (not the token)
//     assert(() {
//       final hasAuth = headers.containsKey('Authorization');
//       final tokenLen = token?.length ?? 0;
//       // Use print here to show in debug consoles
//       print('ApiUtils: getAuthenticatedHeaders -> Authorization present=$hasAuth, tokenLength=$tokenLen');
//       return true;
//     }());

//     return headers;
//   }

//   /// Check if user is currently authenticated
//   static bool isAuthenticated() {
//     return TokenManager().isAuthenticated();
//   }
// }



// api_utils.dart

import 'token_manager.dart';

/// Centralized utility for common API-related operations
class ApiUtils {
  /// Returns standard headers with Bearer token if user is logged in
  static Map<String, String> getAuthenticatedHeaders({
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?additionalHeaders, // Merge any extra headers (e.g. for file uploads)
    };

    final token = TokenManager().getToken();

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Debug helper — only runs in debug mode
    assert(() {
      final hasAuth = headers.containsKey('Authorization');
      final tokenLength = token?.length ?? 0;
      print('ApiUtils: Headers → Auth=$hasAuth, TokenLength=$tokenLength');
      return true;
    }());

    return headers;
  headers;
  }

  /// Check if user is currently authenticated (token exists + not expired)
  static bool isAuthenticated() => TokenManager().isAuthenticated;

  /// Shortcut: Check if token exists (ignores expiry — useful for UI decisions)
  static bool hasToken() => TokenManager().getToken() != null;

  /// Optional: Force refresh token check (rarely needed)
  static void refreshAuthState() {
    if (TokenManager().isAuthenticated == false) {
      // You can trigger logout navigation here if needed
      // e.g., TokenManager().logout();
    }
  }
}