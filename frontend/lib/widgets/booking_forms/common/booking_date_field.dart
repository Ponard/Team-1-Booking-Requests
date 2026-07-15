import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:flutter/material.dart';

class BookingDateField extends StatelessWidget {
  final TextEditingController controller;

  final String label;

  final DateTime firstDate;

  final DateTime lastDate;

  final bool enabled;

  final FormFieldValidator<String>? validator;

  const BookingDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.firstDate,
    required this.lastDate,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return BookingTextField(
      controller: controller,
      label: label,
      hint: "YYYY-MM-DD",
      enabled: enabled,
      readOnly: true,
      validator: validator,
      suffixIcon: const Icon(Icons.calendar_today),
      onTap: () async {
        if (!enabled) return;

        FocusScope.of(context).unfocus();

        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
        );

        if (picked != null) {
          controller.text =
              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        }
      },
    );
  }
}
