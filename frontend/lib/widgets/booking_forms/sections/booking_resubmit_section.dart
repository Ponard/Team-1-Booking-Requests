import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:flutter/material.dart';

class BookingResubmitSection extends StatelessWidget {
  final VoidCallback onResubmit;

  const BookingResubmitSection({
    super.key,
    required this.onResubmit,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSection(
      leading: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange,
      ),
      title: 'Booking Declined',
      backgroundColor: Colors.orange.shade50,
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.orange,
      ),
      children: [
        const Text(
          'Your booking was declined. Please make the necessary changes and resubmit.',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Resubmit Booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: onResubmit,
          ),
        ),
      ],
    );
  }
}
