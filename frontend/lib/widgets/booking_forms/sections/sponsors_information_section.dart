import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:flutter/material.dart';

class SponsorsInformationSection extends StatefulWidget {
  final List<TextEditingController> sponsorsControllers;
  final int maxSponsors;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  const SponsorsInformationSection({
    super.key,
    required this.sponsorsControllers,
    required this.maxSponsors,
    required this.onChanged,
    this.enabled = true,
  }) : assert(maxSponsors >= -1);

  @override
  State<SponsorsInformationSection> createState() =>
      _SponsorsInformationSectionState();
}

class _SponsorsInformationSectionState
    extends State<SponsorsInformationSection> {
  // Tracks exactly which controllers have _notifyChanged attached.
  final Set<TextEditingController> _attachedControllers = {};

  @override
  void initState() {
    super.initState();

    if (widget.maxSponsors > 0 && widget.sponsorsControllers.isEmpty) {
      widget.sponsorsControllers.add(TextEditingController());
    }

    _reconcileListeners();
    _notifyChanged();
  }

  @override
  void didUpdateWidget(covariant SponsorsInformationSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.maxSponsors != widget.maxSponsors) {
      if (widget.maxSponsors <= 0) {
        // Remove all inputs when no parish is selected or the limit is zero.
        for (final controller in widget.sponsorsControllers.toList()) {
          widget.sponsorsControllers.remove(controller);
          controller.dispose();
        }
      } else {
        // Remove excess inputs when the new parish has a lower limit.
        while (widget.sponsorsControllers.length > widget.maxSponsors) {
          widget.sponsorsControllers.removeLast().dispose();
        }

        // Ensure at least one input exists for a positive limit.
        if (widget.sponsorsControllers.isEmpty) {
          widget.sponsorsControllers.add(TextEditingController());
        }
      }

      _reconcileListeners();
      _notifyChanged();
    } else {
      // Reconcile even when the parent mutates the same list instance.
      _reconcileListeners();
    }
  }

  void _reconcileListeners() {
    final currentControllers = widget.sponsorsControllers.toSet();

    // Detach listeners from controllers no longer in the list.
    final removedControllers =
        _attachedControllers.difference(currentControllers).toList();

    for (final controller in removedControllers) {
      controller.removeListener(_notifyChanged);
      _attachedControllers.remove(controller);
    }

    // Attach listeners to newly added controllers.
    for (final controller in currentControllers) {
      if (_attachedControllers.add(controller)) {
        controller.addListener(_notifyChanged);
      }
    }
  }

  void _notifyChanged() {
    widget.onChanged(
      widget.sponsorsControllers
          .map((controller) => controller.text.trim())
          .where((name) => name.isNotEmpty)
          .toList(),
    );
  }

  void _addSponsor() {
    if (!widget.enabled ||
        widget.sponsorsControllers.length >= widget.maxSponsors) {
      return;
    }

    final controller = TextEditingController();

    setState(() {
      widget.sponsorsControllers.add(controller);
      _reconcileListeners();
    });

    _notifyChanged();
  }

  void _removeSponsor(int index) {
    if (!widget.enabled ||
        index < 0 ||
        index >= widget.sponsorsControllers.length) {
      return;
    }

    final controller = widget.sponsorsControllers[index];

    setState(() {
      widget.sponsorsControllers.removeAt(index);
      _reconcileListeners();
    });

    // The parent owns the list, but this widget created no-longer-needed
    // controllers only through _addSponsor; the parent also disposes
    // the controllers in its list during screen disposal.
    controller.dispose();

    _notifyChanged();
  }

  @override
  void dispose() {
    for (final controller in _attachedControllers) {
      controller.removeListener(_notifyChanged);
    }

    _attachedControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sponsors = widget.sponsorsControllers;
    final canAdd = sponsors.length < widget.maxSponsors;

    return BookingSection(
      title: 'Sponsors / Godparents',
      children: [
        if (widget.maxSponsors == -1)
          const Text('Please select a parish first.')
        else if (widget.maxSponsors == 0)
          const Text('Godparents are not available for this booking.')
        else ...[
          Text(
            'Add up to ${widget.maxSponsors} '
            '${widget.maxSponsors == 1 ? 'godparent' : 'godparents'}.',
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < sponsors.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BookingTextField(
                    enabled: widget.enabled,
                    controller: sponsors[i],
                    label: 'Godparent ${i + 1} *',
                    validator: Validators.requiredField,
                  ),
                ),
                if (sponsors.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Remove godparent ${i + 1}',
                    onPressed: widget.enabled ? () => _removeSponsor(i) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (canAdd)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.enabled ? _addSponsor : null,
                icon: const Icon(Icons.add),
                label: const Text('Add godparent'),
              ),
            ),
        ],
      ],
    );
  }
}
