import 'dart:developer';

import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  static Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    log("App Name: $appName");
    log("Package Name: $packageName");
    log("Version: $version");
    log("Build Number: $buildNumber");

    return "v $version";
  }
}
