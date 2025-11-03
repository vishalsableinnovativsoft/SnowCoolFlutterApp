import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
import '../utils/token_manager.dart';
import 'home_screen.dart';
import '../services/login_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginApi _api = LoginApi();
  bool _loading = false;
  bool _usernameInvalid = false;
  bool _passwordInvalid = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both username and password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Reset previous validation state
    setState(() {
      _usernameInvalid = false;
      _passwordInvalid = false;
      _errorMessage = null;
      _loading = true;
    });

    // Demo credentials check (local demo) — adjust these values as needed.
    const demoUsername = 'demo';
    const demoPassword = 'demo123';

    // Quick client-side demo validation: if matches demo creds, navigate locally.
    if (username == demoUsername && password == demoPassword) {
      // Set a demo token for demo mode
      TokenManager().setToken('demo-token-local-only');

      setState(() => _loading = false);
      // Ensure widget is still mounted before navigating to avoid scheduling
      // navigation after the widget tree was disposed (which can cause the
      // "Trying to render a disposed EngineFlutterView" exception on web).
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      return;
    }

    // If demo creds didn't match, show error for demo or call backend to validate credentials.

    // Try API login first, fallback to demo if network fails
    try {
      final resp = await _api.login(username, password);

      setState(() {
        _loading = false;
        if (resp.success) {
          // Store the token for future API calls
          if (resp.token != null) {
            TokenManager().setToken(resp.token);
            print('Token stored: ${resp.token}');
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Show professional error message
          _errorMessage =
              resp.message ??
              'Incorrect username or password. Please try again.';
          if (resp.field == 'username') {
            _usernameInvalid = true;
          } else if (resp.field == 'password') {
            _passwordInvalid = true;
          } else {
            // Mark both fields invalid if no specific field error
            _usernameInvalid = true;
            _passwordInvalid = true;
          }
        }
      });
    } catch (e) {
      // Network error or API unavailable - show professional fallback error
      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to connect to the server. Please check your internet connection and try again.';
        _usernameInvalid = false;
        _passwordInvalid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Responsive form width: username pe 360 fixed, tablet pe 50% screen (max 500 for clean).
    final formWidth = width > 600 ? (width * 0.5).clamp(360.0, 500.0) : 360.0;

    return Scaffold(
      body: Stack(
        children: [
          // Bottom white container - full width, form left-aligned inside with fixed padding.
          Positioned(
            top: height * 0.5,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16,
                ), // Fixed padding for left-align.
                child: _LoginFormWrapper(
                  formWidth: formWidth, // Pass responsive width.
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  loading: _loading,
                  usernameInvalid: _usernameInvalid,
                  passwordInvalid: _passwordInvalid,
                  errorMessage: _errorMessage,
                  onUsernameChanged: (v) {
                    if (_usernameInvalid || _errorMessage != null) {
                      setState(() {
                        _usernameInvalid = false;
                        _errorMessage = null;
                      });
                    }
                  },
                  onPasswordChanged: (v) {
                    if (_passwordInvalid || _errorMessage != null) {
                      setState(() {
                        _passwordInvalid = false;
                        _errorMessage = null;
                      });
                    }
                  },
                  onLoginPressed: _doLogin,
                ),
              ),
            ),
          ),
          // Background image same.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height * 0.5,
            child: Image.asset(
              'assets/images/background_cylinders.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Gradient overlay same.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryBlue,
                    const Color.fromRGBO(0, 174, 239, 0.32),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.444, 1.0],
                ),
              ),
            ),
          ),
          // Waterfall same.
          Positioned(
            top: height * 0.222,
            left: 0,
            right: 0,
            height: height * 0.3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                ),
              ),
            ),
          ),
          // Logo centered same.
          Positioned(
            top: height * 0.15,
            left: 0,
            right: 0,
            child: _buildLogo(),
          ),
        ],
      ),
    );
  }

  // Logo unchanged.
  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.95),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SNOWCOOL',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'TRADING CO.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryBlue,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Form wrapper - responsive width, fields/button full inside.
class _LoginFormWrapper extends StatelessWidget {
  final double formWidth;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool loading;
  final bool usernameInvalid;
  final bool passwordInvalid;
  final String? errorMessage;
  final ValueChanged<String>? onUsernameChanged;
  final ValueChanged<String>? onPasswordChanged;
  final VoidCallback onLoginPressed;

  const _LoginFormWrapper({
    required this.formWidth,
    required this.usernameController,
    required this.passwordController,
    required this.loading,
    this.usernameInvalid = false,
    this.passwordInvalid = false,
    this.errorMessage,
    this.onUsernameChanged,
    this.onPasswordChanged,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: formWidth, // Responsive width.
      height: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned.
          children: [
            const SizedBox(height: 40),
            // Title left-aligned.
            Container(
              width: double.infinity, // Full form width.
              alignment: Alignment
                  .centerLeft, // Left for title too? Or center? Left rakha.
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                  color: AppColors.accentBlue,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Username',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                color: AppColors.accentBlue,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            CustomTextField(
              // Will be double.infinity in widget.
              controller: usernameController,
              label: '',
              hint: 'Enter your username',
              keyboardType: TextInputType.phone,
              icon: Icons.person,
              textColor: Colors.black87,
              borderColor: usernameInvalid ? Colors.red : null,
              onChanged: onUsernameChanged,
            ),
            const SizedBox(height: 17),
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                color: AppColors.accentBlue,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            CustomTextField(
              controller: passwordController,
              label: '',
              hint: 'Enter password',
              obscureText: true,
              icon: Icons.lock,
              textColor: Colors.black87,
              borderColor: passwordInvalid ? Colors.red : null,
              onChanged: onPasswordChanged,
            ),
            const SizedBox(height: 17),
            // Professional error message display
            if (errorMessage != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            CustomButton(
              // Full width inside form.
              text: loading ? 'Please wait...' : 'Log In',
              bgColor: AppColors.accentBlue,
              textColor: Colors.white,
              borderRadius: 10,
              height: 46,
              onPressed: loading ? () {} : onLoginPressed,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
