import 'package:diocese_frontend/utils/validators.dart';
import 'package:flutter/material.dart';

import '../common/booking_date_field.dart';
import '../common/booking_section.dart';
import '../common/booking_text_field.dart';

class ChildInformationSection extends StatelessWidget {
  final TextEditingController childNameController;
  final TextEditingController dobController;

  final bool enabled;

  const ChildInformationSection({
    super.key,
    required this.childNameController,
    required this.dobController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSection(
      title: "Child Information",
      children: [
        BookingTextField(
          controller: childNameController,
          label: "Child's Full Name *",
          enabled: enabled,
          validator: Validators.requiredField,
        ),
        BookingDateField(
          controller: dobController,
          label: "Date of Birth *",
          enabled: enabled,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          validator: Validators.requiredField,
        ),
      ],
    );
  }
}
