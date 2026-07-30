// extensions/build_context_extensions.dart

import 'package:diocese_frontend/models/api_response.dart';
import 'package:flutter/material.dart';

extension BookingStatusExtension on BuildContext {
  Future<void> handleBookingStatusUpdate(
    Future<ApiResponse> request,
    String status,
  ) async {
    final result = await request;

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(content: Text('Booking marked as $status')),
      );
      Navigator.pop(this, true);
    } else {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed')),
      );
    }
  }
}
