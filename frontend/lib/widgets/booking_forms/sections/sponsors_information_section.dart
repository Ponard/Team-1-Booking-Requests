import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:flutter/material.dart';

class SponsorsInformationSection extends StatelessWidget {
  final TextEditingController godparentsController;

  const SponsorsInformationSection({
    super.key,
    required this.godparentsController,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSection(
      title: 'Sponsors / Godparents',
      children: [
        BookingTextField(
          controller: godparentsController,
          label: "Godparents' Details *",
          validator: Validators.requiredField,
        ),
      ],
    );
  }
}
