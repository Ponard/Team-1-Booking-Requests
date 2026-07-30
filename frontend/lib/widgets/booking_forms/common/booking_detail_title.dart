import 'package:diocese_frontend/widgets/booking_forms/status/booking_status_badge.dart';
import 'package:flutter/material.dart';

class BookingDetailTitle extends StatelessWidget {
  const BookingDetailTitle({
    super.key,
    required this.title,
    this.status,
  });

  final String title;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (status != null) ...[
          const SizedBox(width: 10),
          BookingStatusBadge(status: status!),
        ],
      ],
    );
  }
}
