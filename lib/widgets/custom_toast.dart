import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

void showSuccessToast(BuildContext context, String message) {
  _showSmartToast(
    context,
    message,
    icon: Icons.check_circle_rounded,
    backgroundColor: const Color(0xFF4CAF50),
    animation: StyledToastAnimation.slideFromBottom,
    reverseAnimation: StyledToastAnimation.slideToBottom,
    isSuccess: true,
  );
}

/// Error Toast: Always at Top
void showErrorToast(BuildContext context, String message) {
  _showSmartToast(
    context,
    message,
    icon: Icons.error_outline_rounded,
    backgroundColor: const Color(0xFFE53935),
    animation: StyledToastAnimation.slideFromTop,
    reverseAnimation: StyledToastAnimation.slideToTop,
    isSuccess: false,
  );
}

/// Warning Toast: Always at Top
void showWarningToast(BuildContext context, String message) {
  _showSmartToast(
    context,
    message,
    icon: Icons.warning_amber_rounded,
    backgroundColor: const Color(0xFFFFC107),
    animation: StyledToastAnimation.slideFromTop,
    reverseAnimation: StyledToastAnimation.slideToTop,
    isSuccess: false,
  );
}

/// Unified smart toast with perfect positioning
void _showSmartToast(
  BuildContext context,
  String message, {
  required IconData icon,
  required Color backgroundColor,
  required StyledToastAnimation animation,
  required StyledToastAnimation reverseAnimation,
  required bool isSuccess,
}) {
  final media = MediaQuery.of(context);
  final keyboardHeight = media.viewInsets.bottom;
  final isKeyboardOpen = keyboardHeight > 100;

  // Toast Widget (unchanged – beautiful as always)
  final toastWidget = Material(
    color: Colors.transparent,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // PERFECT POSITIONING LOGIC (This is the magic)
  Alignment alignment;

  if (isSuccess) {
    if (isKeyboardOpen) {
      // Show just above keyboard (never hidden)
      alignment = const Alignment(0, 0.65); // Perfect: 65% from top → always visible
    } else {
      // Normal success → bottom of screen (like WhatsApp, Instagram)
      alignment = const Alignment(0, 0.92);
    }
  } else {
    // Error & Warning → always top (like login failures)
    alignment = const Alignment(0, -0.92);
  }

  showToastWidget(
    toastWidget,
    context: context,
    animation: animation,
    reverseAnimation: reverseAnimation,
    duration: const Duration(seconds: 4),
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
    alignment: alignment,
    animDuration: const Duration(milliseconds: 400),
    position: StyledToastPosition(align: alignment),
  );
}