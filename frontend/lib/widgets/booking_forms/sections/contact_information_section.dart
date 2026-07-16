import 'package:flutter/material.dart';

import '../common/booking_section.dart';
import '../common/booking_text_field.dart';

class ContactInformationSection extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;

  final bool enabled;

  final String? Function(String?)? emailValidator;
  final String? Function(String?)? phoneValidator;

  const ContactInformationSection({
    super.key,
    required this.emailController,
    required this.phoneController,
    this.enabled = true,
    this.emailValidator,
    this.phoneValidator,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSection(
      title: "Contact Information",
      children: [
        BookingTextField(
          controller: emailController,
          label: "Email *",
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          validator: emailValidator,
        ),
        BookingTextField(
          controller: phoneController,
          label: "Contact Number *",
          enabled: enabled,
          keyboardType: TextInputType.phone,
          validator: phoneValidator,
        ),
      ],
    );
  }
}
