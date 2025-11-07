import 'dart:math';

import 'package:flutter/material.dart';
import 'package:snow_trading_cool/utils/token_manager.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
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
      showWarningToast(context, "Please enter both username and password");
      return;
    }

    // Close keyboard on login press to avoid overflow with error message
    FocusScope.of(context).unfocus();

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
      showSuccessToast(context, "Logged in successfully");
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

      if (resp.success) {
        // Store the token for future API calls
        if (resp.token != null) {
          TokenManager().setToken(resp.token);
          print('Token stored: ${resp.token}');
        }

        setState(() => _loading = false); // Success: No delay, fast navigate
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // *** ERROR CASE: Delay add karo yahan (keyboard animation complete hone tak) ***
        await Future.delayed(
          const Duration(milliseconds: 300),
        ); // Increased to 300ms for safety
        if (!mounted) return;
        setState(() {
          _loading = false;
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
        });
      }
    } catch (e) {
      // *** ERROR CASE (Network): Delay add karo yahan ***
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Same delay for catch
      if (!mounted) return;
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
    final viewInsets = MediaQuery.of(
      context,
    ).viewInsets; // Keyboard detect ke liye
    final isKeyboardOpen = viewInsets.bottom > 0; // Direct keyboard flag

    // Dynamic heights for shrink effect
    final topHeight =
        (height * 0.5) - (viewInsets.bottom * 0.6).clamp(0.0, height * 0.2);
    // Base form top - uniform for all screens to keep consistent UI
    final baseFormTop = height * 0.5;
    // Min top: simplified, consistent across devices
    final minFormTop = isKeyboardOpen ? height * 0.3 : height * 0.10;
    final formTop = (baseFormTop - viewInsets.bottom).clamp(
      minFormTop,
      baseFormTop,
    );
    final waterfallTop = (height * 0.222) - (viewInsets.bottom * 0.4);
    final waterfallHeight = (height * 0.3) + (viewInsets.bottom * 0.2);

    // Responsive form width: on tablet use 50% (clamped), on mobile fit within
    // the available width minus padding so it never overflows smaller phones.
    final formWidth = width > 600
        ? (width * 0.5).clamp(360.0, 500.0)
        : (width - 40).clamp(280.0, 360.0);

    return Scaffold(
      resizeToAvoidBottomInset: false, // Keyboard pe no resize, no overflow
      body: Stack(
        children: [
          // Bottom white container - full width, form left-aligned inside with fixed padding.
          Positioned(
            // Lift the form up by the keyboard inset so the login button never
            // gets hidden. When keyboard isn't open viewInsets.bottom == 0.
            top: formTop, // Adjusted dynamic top with clamp
            left: 0,
            right: 0,
            bottom: viewInsets.bottom,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ), // Explicit decoration for clipBehavior
              clipBehavior:
                  Clip.hardEdge, // Clip any potential overflow without error
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16,
                ), // Fixed padding for left-align.
                child: _LoginFormWrapper(
                  formWidth: formWidth, // Pass responsive width.
                  isKeyboardOpen:
                      isKeyboardOpen, // Pass flag for compact only on keyboard
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
          // Background image - shrink on keyboard
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topHeight, // Dynamic height!
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
          // Gradient overlay - same shrink
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topHeight, // Dynamic!
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
          // Waterfall adjust - HIDE when keyboard open
          if (!isKeyboardOpen)
            Positioned(
              top: waterfallTop.clamp(0.0, height * 0.3), // Don't go negative
              left: 0,
              right: 0,
              height: waterfallHeight.clamp(
                height * 0.1,
                height * 0.4,
              ), // Min/max for safety
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
          // Logo dynamic top - FIXED clamp to avoid ArgumentError, thoda upar for keyboard
          Positioned(
            top: () {
              final computedTop =
                  topHeight *
                  0.25; // Thoda chhota kar diya (0.3 se 0.25) for upar shift
              final minTop = 20.0;
              final maxTop = height * 0.15;
              final effectiveUpper = max(
                minTop,
                maxTop,
              ); // Ensure upper >= lower
              return computedTop.clamp(minTop, effectiveUpper);
            }(),
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
  final bool isKeyboardOpen; // Flag for compact ONLY on keyboard
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
    required this.isKeyboardOpen,
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
    // Always use compact mode when keyboard is open or error is shown
    final bool isCompactOrError = isKeyboardOpen || errorMessage != null;
    // Use even more compact spacing when both keyboard and error are present
    final bool isSuperCompact = isKeyboardOpen && errorMessage != null;

    // Adjust all spacings to be more compact
    final topPadding = isSuperCompact ? 0.0 : (isCompactOrError ? 2.0 : 20.0);
    final gapSize = isSuperCompact ? 2.0 : (isCompactOrError ? 4.0 : 12.0);
    final bottomSpacing = isSuperCompact
        ? 0.0
        : (isCompactOrError ? 2.0 : 16.0);
    final errorVerticalPadding = isSuperCompact
        ? 2.0
        : (isCompactOrError ? 4.0 : 8.0);
    final titleFontSize = isSuperCompact
        ? 14.0
        : (isCompactOrError ? 16.0 : 18.0);
    final labelFontSize = isSuperCompact
        ? 10.0
        : (isCompactOrError ? 11.0 : 13.0);
    final buttonHeight = isSuperCompact
        ? 32.0
        : (isCompactOrError ? 36.0 : 42.0);
    final errorIconSize = isSuperCompact
        ? 10.0
        : (isCompactOrError ? 12.0 : 16.0);
    final errorGap = isSuperCompact ? 2.0 : (isCompactOrError ? 4.0 : 8.0);
    final errorLineHeight = isSuperCompact
        ? 1.0
        : (isCompactOrError ? 1.1 : 1.2);
    final fieldHeight = isSuperCompact
        ? 40.0
        : (isCompactOrError ? 44.0 : 52.0);

    return SizedBox(
      width: formWidth,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned.
          children: [
            SizedBox(height: topPadding),
            // Title left-aligned.
            Container(
              width: double.infinity, // Full form width.
              alignment: Alignment
                  .centerLeft, // Left for title too? Or center? Left rakha.
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                'Log In',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                  color: AppColors.accentBlue,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            SizedBox(height: gapSize),
            Text(
              'Username',
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                color: AppColors.accentBlue,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              // Dynamic height for centered text, with alignment
              height: fieldHeight,
              child: Align(
                alignment:
                    Alignment.centerLeft, // Force left-center for text inside
                child: CustomTextField(
                  controller: usernameController,
                  label: '',
                  hint: 'Enter your username',
                  icon: Icons.person,
                  textColor: Colors.black87,
                  borderColor: usernameInvalid ? Colors.red : null,
                  onChanged: onUsernameChanged,
                ),
              ),
            ),
            SizedBox(height: gapSize),
            Text(
              'Password',
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                color: AppColors.accentBlue,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              // Same for password - dynamic height, centered
              height: fieldHeight,
              child: Align(
                alignment: Alignment.centerLeft, // Force left-center
                child: CustomTextField(
                  controller: passwordController,
                  label: '',
                  hint: 'Enter password',
                  obscureText: true,
                  enablePasswordToggle: true,
                  icon: Icons.lock,
                  textColor: Colors.black87,
                  borderColor: passwordInvalid ? Colors.red : null,
                  onChanged: onPasswordChanged,
                ),
              ),
            ),
            SizedBox(height: gapSize),
            // Professional error message display - compact if keyboard open
            if (errorMessage != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: errorVerticalPadding,
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
                      size: errorIconSize, // Dynamic icon size
                    ),
                    SizedBox(width: errorGap),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: errorLineHeight, // Dynamic line height
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isCompactOrError ? 6.0 : 16.0),
            ],
            SizedBox(
              height: buttonHeight,
              child: CustomButton(
                // Full width inside form.
                text: loading ? 'Please wait...' : 'Log In',
                bgColor: AppColors.accentBlue,
                textColor: Colors.white,
                borderRadius: 10,
                height: buttonHeight, // Dynamic height
                onPressed: loading ? () {} : onLoginPressed,
              ),
            ),
            SizedBox(height: bottomSpacing),
          ],
        ),
      ),
    );
  }
}
