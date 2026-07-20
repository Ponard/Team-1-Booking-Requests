import 'booking_field_handle.dart';

class BookingFormController {
  final List<BookingFieldHandle> _fields = [];

  void register(BookingFieldHandle field) {
    if (!_fields.contains(field)) {
      _fields.add(field);
    }
  }

  void unregister(BookingFieldHandle field) {
    _fields.remove(field);
  }

  void focusFirstInvalid() {
    for (final field in _fields) {
      if (field.hasError) {
        field.focus();
        break;
      }
    }
  }
}
