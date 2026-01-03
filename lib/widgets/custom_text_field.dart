import 'package:flutter/material.dart';
import 'package:snow_trading_cool/utils/constants.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final bool obscureText;
  final bool enablePasswordToggle;
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
    this.enablePasswordToggle = false,
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
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _controller;
  late final bool _ownController;
  bool _hasText = false;
  late bool _obscureText;

  void _listener() {
    final has = _controller.text.isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  void _toggleObscure() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  void initState() {
    super.initState();
    _ownController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _obscureText = widget.obscureText;
    _controller.addListener(_listener);
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    if (_ownController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      cursorColor: AppColors.accentBlue,
      style: TextStyle(color: widget.textColor ?? Colors.black87),
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textAlign: TextAlign.start, // Always left-aligned, no center for hint
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: widget.hintStyle ?? const TextStyle(color: Colors.grey),
        labelStyle: TextStyle(color: widget.labelColor ?? Colors.grey),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color.fromRGBO(156, 156, 156, 1)),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, top: 0, bottom: 0),
          child: Icon(widget.icon, color: widget.iconColor ?? Colors.grey),
        ),
        suffixIcon: widget.enablePasswordToggle
            ? Padding(
                padding: const EdgeInsets.only(right: 12, top: 0, bottom: 0),
                child: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: _toggleObscure,
                ),
              )
            : null,
      ),
    );
  }
}
