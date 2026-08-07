import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:flutter/material.dart';

class BookingStatusActionsSection extends StatelessWidget {
  const BookingStatusActionsSection({
    super.key,
    required this.status,
    required this.approvalStage,
    required this.role,
    required this.onUpdateStatus,
    required this.onForwardToPriest,
  });

  final String status;
  final String approvalStage;
  final String? role;

  final Future<void> Function(String status) onUpdateStatus;
  final Future<void> Function() onForwardToPriest;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final normalizedStage = approvalStage.toLowerCase();

    final isStaff = role == 'parish_staff' ||
        role == 'parish_admin' ||
        role == 'diocese_staff' ||
        role == 'diocese_admin';

    final isPriest = role == 'priest';

    final canStaffReview =
        normalizedStatus == 'pending' && normalizedStage == 'staff' && isStaff;

    final canPriestReview = normalizedStatus == 'pending' &&
        normalizedStage == 'priest' &&
        isPriest;

    final canComplete = normalizedStatus == 'approved' && isStaff;

    if (!canStaffReview && !canPriestReview && !canComplete) {
      return const SizedBox.shrink();
    }

    return BookingSection(
      title: 'Actions',
      transparent: true,
      padding: 0,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canStaffReview) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.forward),
                      label: const Text('Forward to Priest'),
                      onPressed: onForwardToPriest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onPressed: () => onUpdateStatus('declined'),
                    ),
                  ),
                ],
              ),
            ],
            if (canPriestReview)
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
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onPressed: () => onUpdateStatus('declined'),
                    ),
                  ),
                ],
              ),
            if (canComplete)
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
        ),
      ],
    );
  }
}
