import 'package:flutter/material.dart';

class BookingStatus {
  const BookingStatus._();

  static Color getColor(BuildContext context, String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
