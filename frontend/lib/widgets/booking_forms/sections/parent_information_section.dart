import 'package:diocese_frontend/utils/validators.dart';
import 'package:flutter/material.dart';

import '../common/booking_section.dart';
import '../common/booking_text_field.dart';

class ParentInformationSection extends StatelessWidget {
  final TextEditingController fatherController;
  final TextEditingController motherController;

  final bool enabled;

  const ParentInformationSection({
    super.key,
    required this.fatherController,
    required this.motherController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSection(
      title: "Parent Information",
      children: [
        BookingTextField(
          controller: fatherController,
          label: "Father's Name *",
          enabled: enabled,
          validator: Validators.requiredField,
        ),
        const SizedBox(width: 12),
        BookingTextField(
          controller: motherController,
          label: "Mother's Name *",
          enabled: enabled,
          validator: Validators.requiredField,
        ),
      ],
    );
  }
}
