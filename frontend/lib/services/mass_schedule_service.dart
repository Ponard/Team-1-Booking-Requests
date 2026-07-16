import 'dart:convert';
import '../models/mass_schedule.dart';
import '../models/api_response.dart';
import 'api_client.dart';

class MassScheduleService {
  static final MassScheduleService _instance = MassScheduleService._internal();
  factory MassScheduleService() => _instance;
  MassScheduleService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<MassSchedule>>> getAllMassSchedules({
    int? parishId,
  }) async {
    try {
      String endpoint = '/api/mass-schedules';
      if (parishId != null) {
        endpoint += '?parishId=$parishId';
      }

      final response = await _apiClient.getWithAuth(endpoint);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final schedules = (data['massSchedules'] as List)
            .map((json) => MassSchedule.fromJson(json))
            .toList();

        return ApiResponse<List<MassSchedule>>(
          success: true,
          data: schedules,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<List<MassSchedule>>(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch mass schedules',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<MassSchedule>>(
        success: false,
        message: 'Network error fetching mass schedules',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<MassSchedule>> createMassSchedule({
    required int parishId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    int? priestId,
    String? intentionCutoffTime,
    String? notes,
  }) async {
    try {
      final requestBody = {
        'parishId': parishId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        if (priestId != null) 'priestId': priestId,
        if (intentionCutoffTime != null) 'intentionCutoffTime': intentionCutoffTime,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiClient.postWithAuth(
        '/api/mass-schedules',
        json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final schedule = MassSchedule.fromJson(data['massSchedule'] ?? data);

        return ApiResponse<MassSchedule>(
          success: true,
          data: schedule,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<MassSchedule>(
          success: false,
          message: errorData['message'] ?? 'Failed to create mass schedule',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<MassSchedule>(
        success: false,
        message: 'Network error creating mass schedule',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<MassSchedule>> updateMassSchedule({
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
    try {
      final requestBody = <String, dynamic>{};
      if (parishId != null) requestBody['parishId'] = parishId;
      if (dayOfWeek != null) requestBody['dayOfWeek'] = dayOfWeek;
      if (startTime != null) requestBody['startTime'] = startTime;
      if (endTime != null) requestBody['endTime'] = endTime;
      if (priestId != null) requestBody['priestId'] = priestId;
      if (intentionCutoffTime != null) requestBody['intentionCutoffTime'] = intentionCutoffTime;
      if (isActive != null) requestBody['isActive'] = isActive;
      if (notes != null) requestBody['notes'] = notes;

      final response = await _apiClient.putWithAuth(
        '/api/mass-schedules/$id',
        json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final schedule = MassSchedule.fromJson(data['massSchedule'] ?? data);

        return ApiResponse<MassSchedule>(
          success: true,
          data: schedule,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<MassSchedule>(
          success: false,
          message: errorData['message'] ?? 'Failed to update mass schedule',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<MassSchedule>(
        success: false,
        message: 'Network error updating mass schedule',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<void>> deleteMassSchedule(int id) async {
    try {
      final response = await _apiClient.deleteWithAuth(
        '/api/mass-schedules/$id',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<void>(
          success: true,
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<void>(
          success: false,
          message: errorData['message'] ?? 'Failed to delete mass schedule',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error deleting mass schedule',
        errors: [e.toString()],
      );
    }
  }
}
