import 'package:flutter/foundation.dart';
import '../models/mass_schedule.dart';
import '../services/mass_schedule_service.dart';

class MassScheduleProvider extends ChangeNotifier {
  final MassScheduleService _service = MassScheduleService();

  List<MassSchedule> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MassSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSchedules({int? parishId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.getAllMassSchedules(parishId: parishId);

    if (result.success && result.data != null) {
      _schedules = result.data!;
    } else {
      _errorMessage = result.message ?? 'Failed to load mass schedules';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createSchedule({
    required int parishId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    int? priestId,
    String? intentionCutoffTime,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.createMassSchedule(
      parishId: parishId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      priestId: priestId,
      intentionCutoffTime: intentionCutoffTime,
      notes: notes,
    );

    _isLoading = false;

    if (result.success && result.data != null) {
      _schedules.add(result.data!);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message ?? 'Failed to create mass schedule';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSchedule({
    required int id,
    int? parishId,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    int? priestId,
    String? intentionCutoffTime,
    bool? isActive,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.updateMassSchedule(
      id: id,
      parishId: parishId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      priestId: priestId,
      intentionCutoffTime: intentionCutoffTime,
      isActive: isActive,
      notes: notes,
    );

    _isLoading = false;

    if (result.success && result.data != null) {
      final index = _schedules.indexWhere((s) => s.id == id);
      if (index != -1) {
        _schedules[index] = result.data!;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message ?? 'Failed to update mass schedule';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSchedule(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.deleteMassSchedule(id);

    _isLoading = false;

    if (result.success) {
      _schedules.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message ?? 'Failed to delete mass schedule';
      notifyListeners();
      return false;
    }
  }

  List<MassSchedule> getSchedulesForDate(DateTime date) {
    final dayName = _getDayName(date.weekday);
    return _schedules
        .where((s) => s.dayOfWeek == dayName && s.isActive)
        .toList();
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
