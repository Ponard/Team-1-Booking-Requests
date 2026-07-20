import 'package:diocese_frontend/providers/priest_provider.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PriestDropdown extends StatelessWidget {
  final int? selectedPriestId;
  final ValueChanged<int?>? onChanged;

  const PriestDropdown({
    super.key,
    required this.selectedPriestId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PriestProvider>(
      builder: (context, priestProvider, _) {
        final validPriestId = selectedPriestId != null &&
                priestProvider.priests.any(
                  (p) => p.id == selectedPriestId,
                )
            ? selectedPriestId
            : null;

        return BookingDropdown<int>(
          initialValue: validPriestId,
          label: 'Preferred Priest (Optional) - Subject to availability',
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('No preference'),
            ),
            ...priestProvider.priests.map(
              (priest) => DropdownMenuItem<int>(
                value: priest.id,
                child: Text(priest.fullName),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}
