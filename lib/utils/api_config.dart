/// Central place to configure API endpoints and related constants.
///
/// Default `baseUrl` targets the Android emulator host (10.0.2.2).
/// If you run the app on a real device change this at startup e.g.
/// `ApiConfig.baseUrl = 'http://192.168.1.100:8080';`
class ApiConfig {
  /// Base URL used by network services. Mutable so you can override at runtime
  /// (for example when detecting device vs emulator).
  // Use localhost:8080 by default; change to 10.0.2.2 when running on Android
  // emulator, or set to your machine LAN IP for physical devices.
  static String baseUrl = 'http://localhost:8081';

  /// Helper to set the base URL at runtime.
  static void setBaseUrl(String url) => baseUrl = url;
}
