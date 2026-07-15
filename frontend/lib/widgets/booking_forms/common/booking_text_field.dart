import 'package:flutter/material.dart';

class BookingTextField extends StatelessWidget {
  final TextEditingController controller;

  final String label;

  final String? hint;

  final bool enabled;

  final bool readOnly;

  final int maxLines;

  final TextInputType keyboardType;

  final Widget? suffixIcon;

  final VoidCallback? onTap;

  final FormFieldValidator<String>? validator;

  const BookingTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
