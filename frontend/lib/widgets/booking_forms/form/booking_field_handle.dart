import 'package:flutter/material.dart';

class BookingFieldHandle {
  final key = GlobalKey<FormFieldState>();
  final focusNode = FocusNode();

  bool get hasError => key.currentState?.hasError ?? false;

  Future<void> focus() async {
    final context = key.currentContext;

    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
      );
    }

    focusNode.requestFocus();
  }

  void dispose() {
    focusNode.dispose();
  }
}
