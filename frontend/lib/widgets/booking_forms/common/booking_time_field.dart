import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:flutter/material.dart';

class BookingTimeField extends StatelessWidget {
  final TextEditingController controller;

  final String label;

  final bool enabled;

  final FormFieldValidator<String>? validator;

  const BookingTimeField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return BookingTextField(
      controller: controller,
      label: label,
      hint: "HH:MM",
      enabled: enabled,
      readOnly: true,
      validator: validator,
      suffixIcon: const Icon(Icons.access_time),
      onTap: () async {
        if (!enabled) return;

        FocusScope.of(context).unfocus();

        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (picked != null) {
          controller.text =
              "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        }
      },
    );
  }
}
