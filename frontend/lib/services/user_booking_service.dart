import 'dart:convert';
import 'package:diocese_frontend/models/paginated_response.dart';

import '../models/api_response.dart';
import '../config/api_config.dart';

class UserBookingService {
  static final UserBookingService _instance = UserBookingService._internal();
  factory UserBookingService() => _instance;
  UserBookingService._internal();

  Future<ApiResponse<PaginatedResponse<dynamic>>> getUserBookings({
    required String token,
    int? page,
    int? limit,
    String? status,
    String? sacramentType,
  }) async {
    try {
      List<String> queryParams = [];
      if (page != null) queryParams.add('page=$page');
      if (limit != null) queryParams.add('limit=$limit');
      if (status != null) queryParams.add('status=$status');
      if (sacramentType != null) {
        queryParams.add('sacramentType=$sacramentType');
      }

      String endpoint = ApiConfig.bookingsEndpoint;
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiConfig.getWithAuth(endpoint, token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = (data['data'] as List).map((json) => json).toList();
        final pagination = data['pagination'];

        return ApiResponse(
          success: true,
          data: PaginatedResponse(
            items: bookings,
            page: pagination['page'],
            limit: pagination['limit'],
            totalItems: pagination['total'],
            totalPages: pagination['totalPages'],
          ),
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          success: false,
          message: errorData['error'] ?? 'Failed to fetch bookings',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error fetching bookings',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getUserBookingById({
    required String token,
    required int id,
  }) async {
    try {
      final response = await ApiConfig.getWithAuth(
        '${ApiConfig.bookingsEndpoint}/$id',
        token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data['data'],
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: errorData['error'] ?? 'Failed to fetch booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error fetching booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateUserBooking({
    required String token,
    required int id,
    Map<String, dynamic>? updateData,
  }) async {
    try {
      final response = await ApiConfig.putWithAuth(
        '${ApiConfig.bookingsEndpoint}/$id',
        token,
        json.encode(updateData ?? {}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data['data'],
          message: data['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: errorData['error'] ?? 'Failed to update booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error updating booking',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<void>> deleteUserBooking({
    required String token,
    required int id,
    String? sacramentType,
  }) async {
    try {
      String endpoint = '${ApiConfig.bookingsEndpoint}/$id';
      if (sacramentType != null) {
        endpoint += '?sacramentType=$sacramentType';
      }
      // print('[deleteUserBooking] DELETE $endpoint');

      final response = await ApiConfig.deleteWithAuth(endpoint, token);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Booking deleted successfully',
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<void>(
          success: false,
          message: errorData['error'] ?? 'Failed to delete booking',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error deleting booking',
        errors: [e.toString()],
      );
    }
  }
}
