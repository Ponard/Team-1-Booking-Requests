import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:flutter/material.dart';

class BookingPreferencesSection extends StatelessWidget {
  final Widget parishDropdown;
  final Widget priestDropdown;

  final TextEditingController preferredDateController;
  final TextEditingController preferredTimeController;

  final bool enabled;

  final DateTime firstDate;
  final DateTime lastDate;

  const BookingPreferencesSection({
    super.key,
    required this.parishDropdown,
    required this.priestDropdown,
    required this.preferredDateController,
    required this.preferredTimeController,
    required this.firstDate,
    required this.lastDate,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSection(
      title: "Booking Preferences",
      children: [
        parishDropdown,
        BookingDateField(
          controller: preferredDateController,
          label: "Preferred Date *",
          enabled: enabled,
          firstDate: firstDate,
          lastDate: lastDate,
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),
        BookingTimeField(
          controller: preferredTimeController,
          label: "Preferred Time Slot *",
          enabled: enabled,
          validator: (v) => v == null || v.isEmpty ? "Required" : null,
        ),
        priestDropdown,
      ],
    );
  }
}
