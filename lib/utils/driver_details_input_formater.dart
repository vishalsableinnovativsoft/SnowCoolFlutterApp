import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class DriverDetailsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Allow typing name and the dash
    if (!text.contains('-')) {
      return newValue;
    }

    final parts = text.split('-');
    if (parts.length > 2) {
      // Prevent multiple dashes
      return oldValue;
    }

    final beforeDash = parts[0].trim();
    final afterDash = parts.length > 1 ? parts[1] : '';

    // Only allow digits after dash, and max 10
    final digitsOnly = afterDash.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 10) {
      return oldValue; // Block input beyond 10 digits
    }

    final cleanedAfterDash = digitsOnly;
    final newText = '$beforeDash - $cleanedAfterDash';

    // Adjust cursor position
    final cursorOffset = newText.length - (afterDash.length - cleanedAfterDash.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }
}