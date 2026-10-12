import 'dart:convert';

import '../config/api_config.dart';

class ParishSettingsService {
  static const String _endpoint = '/api/parish-settings';

  static String _message(dynamic data) {
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    }
    return 'Request failed';
  }

  static Map<String, dynamic> _decode(String body) {
    return Map<String, dynamic>.from(jsonDecode(body) as Map);
  }

  static Future<Map<String, dynamic>> _request(
    Future<dynamic> Function() call,
  ) async {
    final response = await call();
    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(data));
    }

    return data;
  }

  static Future<List<Map<String, dynamic>>> getSlotSettings(
    int parishId,
  ) async {
    final data = await _request(
      () => ApiConfig.getWithAuth(
        '$_endpoint/$parishId/slot-settings',
        null,
      ),
    );

    return List<Map<String, dynamic>>.from(
      (data['settings'] as List? ?? []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  static Future<void> saveSlotSettings(
    int parishId,
    Map<String, dynamic> settings,
  ) async {
    await _request(
      () => ApiConfig.postWithAuth(
        '$_endpoint/$parishId/slot-settings',
        null,
        jsonEncode(settings),
      ),
    );
  }

  static Future<void> deleteSlotSettings(
    int parishId,
    String serviceType,
  ) async {
    await _request(
      () => ApiConfig.deleteWithAuth(
        '$_endpoint/$parishId/slot-settings/'
        '${Uri.encodeComponent(serviceType)}',
        null,
      ),
    );
  }

  static Future<List<Map<String, dynamic>>> getBlackoutDates(
    int parishId,
  ) async {
    final data = await _request(
      () => ApiConfig.getWithAuth(
        '$_endpoint/$parishId/blackout-dates',
        null,
      ),
    );

    return List<Map<String, dynamic>>.from(
      (data['blackoutDates'] as List? ?? []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  static Future<void> saveBlackoutDate(
    int parishId,
    Map<String, dynamic> blackout, {
    int? id,
  }) async {
    await _request(
      () => id == null
          ? ApiConfig.postWithAuth(
              '$_endpoint/$parishId/blackout-dates',
              null,
              jsonEncode(blackout),
            )
          : ApiConfig.putWithAuth(
              '$_endpoint/$parishId/blackout-dates/$id',
              null,
              jsonEncode(blackout),
            ),
    );
  }

  static Future<void> deleteBlackoutDate(
    int parishId,
    int id,
  ) async {
    await _request(
      () => ApiConfig.deleteWithAuth(
        '$_endpoint/$parishId/blackout-dates/$id',
        null,
      ),
    );
  }
}
