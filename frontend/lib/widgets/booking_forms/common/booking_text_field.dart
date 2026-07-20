import 'package:diocese_frontend/widgets/booking_forms/form/booking_field_handle.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:flutter/material.dart';

class BookingTextField extends StatefulWidget {
  final TextEditingController controller;

  final String label;

  final String? hint;

  final bool enabled;

  final bool readOnly;

  final int maxLines;

  final TextInputType keyboardType;

  final Widget? suffixIcon;

  final VoidCallback? onTap;

  final FormFieldValidator<String>? validator;

  @override
  State<BookingTextField> createState() => _BookingTextFieldState();

  const BookingTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onTap,
    this.validator,
  });

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class _BookingTextFieldState extends State<BookingTextField> {
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
      child: TextFormField(
        key: _field.key,
        focusNode: _field.focusNode,
        controller: widget.controller,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        validator: widget.validator,
        onTap: widget.onTap,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          border: const OutlineInputBorder(),
          suffixIcon: widget.suffixIcon,
        ),
      ),
    );
  }
}
