
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:snow_trading_cool/utils/constants.dart'; // Import your constants

class LogoutAnimationScreen extends StatelessWidget {
  const LogoutAnimationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = AppColors.accentBlue;
    final Color textColor = isDark ? Colors.white : Colors.white;
    final Color subtitleColor = isDark ? Colors.white70 : Colors.white60;

    return Material(
      color: Colors.black54, // Semi-transparent dark overlay
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Power Icon with Pulse Ring
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulsing ring
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOut,
                    builder: (_, double value, __) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.2),
                          ),
                        ),
                      );
                    },
                  ),
                  // Main circle with icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.power_settings_new_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Animated Wavy Text
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: primaryColor.withOpacity(0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  WavyAnimatedText('Logging out...',
                      speed: const Duration(milliseconds: 120)),
                  WavyAnimatedText('See you soon!',
                      speed: const Duration(milliseconds: 120)),
                  WavyAnimatedText('Stay awesome!',
                      speed: const Duration(milliseconds: 120)),
                ],
                repeatForever: false,
                pause: const Duration(milliseconds: 800),
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              "Clearing your session securely",
              style: TextStyle(
                fontSize: 15,
                color: subtitleColor,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.8,
              ),
            ),

            const SizedBox(height: 8),

            // Small dots animation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}