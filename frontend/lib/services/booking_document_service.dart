import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/document.dart';

class BookingDocumentService {
  Future<ApiResponse<Document>> uploadDocument({
    required String endpoint,
    required int bookingId,
    required PlatformFile file,
    required String documentType,
    required String token,
  }) async {
    try {
      final response = await ApiConfig.sendMultipartWithAuth(
        endpoint: '$endpoint/$bookingId/document',
        fileField: 'document',
        file: file,
        additionalFields: {
          'documentType': documentType,
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Document>(
          success: true,
          message: data['message'],
          data: data['data'] != null ? Document.fromJson(data['data']) : null,
        );
      }

      return ApiResponse<Document>(
        success: false,
        message: data['message'] ?? 'Failed to upload document',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<Document>(
        success: false,
        message: 'Network error uploading document',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<void>> deleteDocument({
    required String endpoint,
    required int bookingId,
    required int documentId,
    required String token,
  }) async {
    try {
      final response = await ApiConfig.deleteWithAuth(
        '$endpoint/$bookingId/document/$documentId',
        token,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: data['message'],
        );
      }

      return ApiResponse<void>(
        success: false,
        message: data['message'] ?? 'Failed to delete document',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error deleting document',
        errors: [e.toString()],
      );
    }
  }

  Future<ApiResponse<void>> replaceDocument({
    required String endpoint,
    required int bookingId,
    required Document document,
    required PlatformFile file,
    required String token,
  }) async {
    final documentType = document.documentType;

    if (document.id == null || documentType == null || documentType.isEmpty) {
      return ApiResponse<void>(
        success: false,
        message: 'Invalid document.',
      );
    }

    final uploadResult = await uploadDocument(
      endpoint: endpoint,
      bookingId: bookingId,
      file: file,
      documentType: documentType,
      token: token,
    );

    if (!uploadResult.success) {
      return ApiResponse<void>(
        success: false,
        message: uploadResult.message,
        errors: uploadResult.errors,
      );
    }

    final deleteResult = await deleteDocument(
      endpoint: endpoint,
      bookingId: bookingId,
      documentId: document.id!,
      token: token,
    );

    if (!deleteResult.success) {
      return deleteResult;
    }

    return ApiResponse<void>(
      success: true,
      message: 'Document replaced successfully',
    );
  }
}
