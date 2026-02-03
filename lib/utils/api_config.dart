/// Central place to configure API endpoints and related constants.
///
/// Default `baseUrl` targets the Android emulator host (10.0.2.2).
/// If you run the app on a real device change this at startup e.g.
/// `ApiConfig.baseUrl = 'http://192.168.1.100:8080';`
class ApiConfig {
  /// Available server URLs
  static const String remoteUrl = 'http://154.61.76.108:8081';
  static const String localUrl = 'http://192.168.1.14:9090';

  /// Toggle between remote and local server (true = remote, false = local)
  static bool useRemoteServer = true;


  /// Base URL used by network services. Automatically switches based on useRemoteServer flag
  static String get baseUrl => useRemoteServer ? remoteUrl : localUrl;

  /// Helper to set the base URL at runtime.
  static void setBaseUrl(String url) {
    if (url == remoteUrl) {
      useRemoteServer = true;
    } else if (url == localUrl) {
      useRemoteServer = false;
    }
  }

  /// Switch to remote server
  static void useRemote() => useRemoteServer = true;

  /// Switch to local server
  static void useLocal() => useRemoteServer = false;

  /// Toggle between remote and local server
  static void toggleServer() => useRemoteServer = !useRemoteServer;
}
