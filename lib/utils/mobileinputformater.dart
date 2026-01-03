import 'package:flutter/services.dart';

class MobileNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Remove all non-digits
    text = text.replaceAll(RegExp(r'\D'), '');

    // Remove leading zeros
    text = text.replaceFirst(RegExp(r'^0+'), '');

    // Limit to 10 digits
    if (text.length > 10) {
      text = text.substring(0, 10);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}