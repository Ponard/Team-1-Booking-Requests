import 'package:flutter/material.dart';

import '../common/booking_section.dart';
import '../common/booking_text_field.dart';

class AdditionalInformationSection extends StatelessWidget {
  final TextEditingController notesController;

  final String label;
  final bool enabled;

  const AdditionalInformationSection({
    super.key,
    this.label = "Additional Notes",
    required this.notesController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSection(
      title: "Additional Information",
      children: [
        BookingTextField(
          controller: notesController,
          label: label,
          enabled: enabled,
          maxLines: 3,
        ),
      ],
    );
  }
}
