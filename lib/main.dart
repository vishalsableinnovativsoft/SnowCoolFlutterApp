import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:snow_trading_cool/screens/home_screen.dart';
import 'package:snow_trading_cool/screens/login_screen.dart';
import 'package:snow_trading_cool/utils/constants.dart';
import 'package:snow_trading_cool/utils/secure_storage.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorage().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This runs once at app start — checks saved login + token expiry
  Future<bool> _checkLoginAndTokenValidity() async {
    final token = SecureStorage().getTokenSync(); // we'll add this helper below
    if (token == null || token.isEmpty) return false;

    // If token is expired → clear everything and force login
    if (SecureStorage().isTokenExpiredSync(token)) {
      await SecureStorage().logout();
      return false;
    }

    // Token is valid → restore full session
    final userId = SecureStorage().getUserIdSync();
    final role = SecureStorage().getRoleSync();
    final permissionsJson = SecureStorage().getPermissionsJsonSync();

    Map<String, dynamic>? permissions;
    if (permissionsJson != null) {
      try {
        permissions = jsonDecode(permissionsJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    TokenManager().login(
      token: token,
      id: userId ?? 0,
      role: role ?? 'USER', 
      permissions: permissions,
    );

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snowcool Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginAndTokenValidity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: customLoader()),
            );
          }

          final isLoggedIn = snapshot.data ?? false;

          return isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}