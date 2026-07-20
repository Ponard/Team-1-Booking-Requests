import 'package:diocese_frontend/widgets/booking_forms/form/booking_field_handle.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:flutter/material.dart';

class BookingDropdown<T> extends StatefulWidget {
  final T? initialValue;

  final String label;

  final List<DropdownMenuItem<T>> items;

  final ValueChanged<T?>? onChanged;

  final FormFieldValidator<T>? validator;

  @override
  State<BookingDropdown<T>> createState() => _BookingDropdownState<T>();

  const BookingDropdown({
    super.key,
    required this.initialValue,
    required this.label,
    required this.items,
    this.onChanged,
    this.validator,
  });

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: initialValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

class _BookingDropdownState<T> extends State<BookingDropdown<T>> {
  late final BookingFieldHandle _field;

  BookingFormController? _controller;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _field = BookingFieldHandle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_registered) {
      _controller = BookingFormScope.of(context);
      _controller!.register(_field);
      _registered = true;
    }
  }

  @override
  void dispose() {
    _controller?.unregister(_field);
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        key: _field.key,
        focusNode: _field.focusNode,
        initialValue: widget.initialValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
        items: widget.items,
        onChanged: widget.onChanged,
        validator: widget.validator,
      ),
    );
  }
}
