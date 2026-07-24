import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;

  final String hintText;

  final String? labelText;

  final TextInputType keyboardType;
  final TextInputAction? textInputAction;

  final bool obscureText;
  final IconData? icon;
  final Widget? suffixIcon;

  final bool enabled;
  final int maxLines;

  final FocusNode? focusNode;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.obscureText = false,
    this.icon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.withAlpha(20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
