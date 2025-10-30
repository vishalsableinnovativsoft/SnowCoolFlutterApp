import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData icon;
  final Color? textColor;
  final Color? labelColor;
  final TextStyle? hintStyle;
  final Color? iconColor;
  final Color? borderColor;
  final Color? fillColor;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.icon,
    this.textColor,
    this.labelColor,
    this.hintStyle,
    this.iconColor,
    this.borderColor,
    this.fillColor,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor ?? Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor ?? Colors.grey.withOpacity(0.5),
            width: 0.6,
          ),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: textColor ?? Colors.black87),
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: hintStyle ?? const TextStyle(color: Colors.grey),
            labelStyle: TextStyle(color: labelColor ?? Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
              child: Icon(icon, color: iconColor ?? Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
