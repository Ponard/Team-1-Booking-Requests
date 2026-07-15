import 'package:flutter/material.dart';

class BookingDropdown<T> extends StatelessWidget {
  final T? value;

  final String label;

  final List<DropdownMenuItem<T>> items;

  final ValueChanged<T?>? onChanged;

  final FormFieldValidator<T>? validator;

  const BookingDropdown({
    super.key,
    required this.value,
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
        value: value,
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
