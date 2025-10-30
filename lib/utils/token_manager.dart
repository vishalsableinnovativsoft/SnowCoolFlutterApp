/// Simple token manager to store and retrieve authentication tokens
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();

  factory TokenManager() {
    return _instance;
  }

  TokenManager._internal();

  String? _token;

  /// Store the authentication token
  void setToken(String? token) {
    _token = token;
  }

  /// Get the current authentication token
  String? getToken() {
    return _token;
  }

  /// Clear the stored token (for logout)
  void clearToken() {
    _token = null;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _token != null && _token!.isNotEmpty;
  }
}
