import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:flutter/material.dart';

class CoupleInformationSection extends StatelessWidget {
  final TextEditingController groomController;
  final TextEditingController brideController;

  final bool enabled;

  const CoupleInformationSection({
    super.key,
    required this.groomController,
    required this.brideController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSection(
      title: 'Couple Information',
      children: [
        BookingTextField(
          controller: groomController,
          label: "Groom's Full Name *",
          enabled: enabled,
          validator: Validators.requiredField,
        ),
        BookingTextField(
          controller: brideController,
          label: "Bride's Full Name *",
          enabled: enabled,
          validator: Validators.requiredField,
        ),
      ],
    );
  }
}
