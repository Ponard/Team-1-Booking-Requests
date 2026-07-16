import 'package:flutter/material.dart';

class BookingDropdown<T> extends StatelessWidget {
  final T? initialValue;

  final String label;

  final List<DropdownMenuItem<T>> items;

  final ValueChanged<T?>? onChanged;

  final FormFieldValidator<T>? validator;

  const BookingDropdown({
    super.key,
    required this.initialValue,
    required this.label,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: initialValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
