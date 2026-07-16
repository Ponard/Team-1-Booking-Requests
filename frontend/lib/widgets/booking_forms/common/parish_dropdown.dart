import 'package:diocese_frontend/providers/parish_provider.dart';
import 'package:diocese_frontend/providers/priest_provider.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParishDropdown extends StatelessWidget {
  final VoidCallback? onParishChanged;

  const ParishDropdown({
    super.key,
    this.onParishChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ParishProvider>(
      builder: (context, parishProvider, _) {
        return BookingDropdown<int>(
          initialValue: parishProvider.selectedParish?.id,
          label: 'Preferred Parish *',
          items: parishProvider.parishes
              .map(
                (parish) => DropdownMenuItem<int>(
                  value: parish.id,
                  child: Text(parish.name),
                ),
              )
              .toList(),
          validator: (value) => value == null ? 'Please select a parish' : null,
          onChanged: (value) {
            if (value == null) return;

            final parish = parishProvider.parishes.firstWhere(
              (p) => p.id == value,
            );

            parishProvider.selectParish(parish);

            context.read<PriestProvider>().loadPriestsByParish(parish.id!);

            onParishChanged?.call();
          },
        );
      },
    );
  }
}
