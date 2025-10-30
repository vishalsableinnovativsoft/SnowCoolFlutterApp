import 'package:flutter/material.dart'; // Core Flutter library for building UIs.
import 'screens/login_screen.dart'; // Import the login screen for navigation.

void main() {
  // This function runs the app and initializes the MaterialApp.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // Constructor for MyApp - A stateless widget that doesn't change state.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Build method - Returns the root widget of the app.
    return MaterialApp(
      title:
          'Snowcool Inventory', // Title of the app shown in the task switcher.
      theme: ThemeData(
        // App-wide theme - Sets colors, fonts, etc. for consistency.
        primarySwatch: Colors.blue, // Primary color scheme based on blue.
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color.fromRGBO(0, 140, 192, 1),
        ),
        ),
        scaffoldBackgroundColor: Color.fromRGBO(255, 255, 255, 1),
      ),
      home:
          const LoginScreen(), // Sets LoginScreen as the initial route/home page.
      debugShowCheckedModeBanner:
          false, // Hides the debug banner in development mode.
    );
  }
}
