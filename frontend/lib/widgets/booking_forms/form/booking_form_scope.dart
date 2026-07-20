import 'package:flutter/widgets.dart';

import 'booking_form_controller.dart';

class BookingFormScope extends InheritedWidget {
  final BookingFormController controller;

  const BookingFormScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static BookingFormController of(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<BookingFormScope>();

    assert(element != null, 'No BookingFormScope found in context.');

    return (element!.widget as BookingFormScope).controller;
  }

  @override
  bool updateShouldNotify(BookingFormScope oldWidget) => false;
}
