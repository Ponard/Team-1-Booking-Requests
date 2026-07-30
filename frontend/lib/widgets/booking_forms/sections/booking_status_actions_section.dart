import 'package:flutter/material.dart';

class BookingStatusActionsSection extends StatelessWidget {
  const BookingStatusActionsSection({
    super.key,
    required this.visible,
    required this.status,
    required this.onUpdateStatus,
  });

  final bool visible;
  final String status;
  final Future<void> Function(String status) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final normalizedStatus = status.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (['pending', 'approved'].contains(normalizedStatus))
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        const SizedBox(height: 8),
        if (normalizedStatus == 'pending') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => onUpdateStatus('approved'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side:
                        BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  onPressed: () => onUpdateStatus('declined'),
                ),
              ),
            ],
          ),
        ] else if (normalizedStatus == 'approved') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => onUpdateStatus('completed'),
            ),
          ),
        ],
      ],
    );
  }
}
