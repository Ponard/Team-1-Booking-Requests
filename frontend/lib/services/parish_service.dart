import 'dart:convert';
import 'package:http/http.dart';

import '../models/parish.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';

class ParishService {
  static final ParishService _instance = ParishService._internal();
  factory ParishService() => _instance;
  ParishService._internal();

  // Get all active parishes
  Future<ApiResponse<List<Parish>>> getAllParishes({String? token}) async {
    try {
      late final Response response;

      if (token != null) {
        response =
            await ApiConfig.getWithAuth(ApiConfig.parishesEndpoint, token);
      } else {
        response = await ApiConfig.get(ApiConfig.parishesEndpoint);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parishes = (data['data'] as List)
            .map((json) => Parish.fromJson(json))
            .toList();

        return ApiResponse<List<Parish>>(
          success: true,
          data: parishes,
          message: data['message'],
        );
      } else {
        return ApiResponse<List<Parish>>(
          success: false,
          message: 'Failed to fetch parishes',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<Parish>>(
        success: false,
        message: 'Network error fetching parishes',
        errors: [e.toString()],
      );
    }
  }

  // Get parish by ID
  Future<ApiResponse<Parish>> getParishById(int id, {String? token}) async {
    try {
      late final Response response;

      if (token != null) {
        response = await ApiConfig.getWithAuth(
            '${ApiConfig.parishesEndpoint}/$id', token);
      } else {
        response = await ApiConfig.get('${ApiConfig.parishesEndpoint}/$id');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parish = Parish.fromJson(data['data']);

        return ApiResponse<Parish>(
          success: true,
          data: parish,
          message: data['message'],
        );
      } else if (response.statusCode == 404) {
        return ApiResponse<Parish>(
          success: false,
          message: 'Parish not found',
        );
      } else {
        return ApiResponse<Parish>(
          success: false,
          message: 'Failed to fetch parish',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Parish>(
        success: false,
        message: 'Network error fetching parish',
        errors: [e.toString()],
      );
    }
  }

  // Search parishes by name or location
  Future<ApiResponse<List<Parish>>> searchParishes({
    String? query,
    List<String>? services,
    String? token,
  }) async {
    try {
      String endpoint = '${ApiConfig.parishesEndpoint}/search';
      List<String> queryParams = [];

      if (query != null) {
        queryParams.add('query=$query');
      }
      if (services != null && services.isNotEmpty) {
        for (String service in services) {
          queryParams.add('services[]=$service');
        }
      }

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      late final Response response;

      if (token != null) {
        response = await ApiConfig.getWithAuth(endpoint, token);
      } else {
        response = await ApiConfig.get(endpoint);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parishes = (data['data'] as List)
            .map((json) => Parish.fromJson(json))
            .toList();

        return ApiResponse<List<Parish>>(
          success: true,
          data: parishes,
          message: data['message'],
        );
      } else {
        return ApiResponse<List<Parish>>(
          success: false,
          message: 'Failed to search parishes',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<Parish>>(
        success: false,
        message: 'Network error searching parishes',
        errors: [e.toString()],
      );
    }
  }

  // Get parishes by service offered
  Future<ApiResponse<List<Parish>>> getParishesByService(String service,
      {String? token}) async {
    try {
      final endpoint = '${ApiConfig.parishesEndpoint}/by-service/$service';
      late final Response response;

      if (token != null) {
        response = await ApiConfig.getWithAuth(endpoint, token);
      } else {
        response = await ApiConfig.get(endpoint);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parishes = (data['data'] as List)
            .map((json) => Parish.fromJson(json))
            .toList();

        return ApiResponse<List<Parish>>(
          success: true,
          data: parishes,
          message: data['message'],
        );
      } else {
        return ApiResponse<List<Parish>>(
          success: false,
          message: 'Failed to fetch parishes by service',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<Parish>>(
        success: false,
        message: 'Network error fetching parishes by service',
        errors: [e.toString()],
      );
    }
  }
}

