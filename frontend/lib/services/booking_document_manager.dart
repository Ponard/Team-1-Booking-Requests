import 'dart:convert';
import 'dart:io';

import 'package:diocese_frontend/config/api_config.dart';
import 'package:diocese_frontend/models/api_response.dart';
import 'package:diocese_frontend/models/document.dart';
import 'package:diocese_frontend/screens/document_preview_screen.dart';
import 'package:diocese_frontend/services/booking_document_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookingDocumentManager {
  BookingDocumentManager({
    BookingDocumentService? service,
  }) : _service = service ?? BookingDocumentService();

  final BookingDocumentService _service;

  Future<void> openDocument({
    required BuildContext context,
    required Document document,
  }) async {
    if (document.fileUrl == null || document.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL is not available'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(document: document),
      ),
    );
  }

  Future<void> deleteDocument({
    required BuildContext context,
    required String endpoint,
    required int bookingId,
    required Document document,
    required Future<void> Function() reload,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${document.fileName ?? 'this document'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final result = await _service.deleteDocument(
      endpoint: endpoint,
      bookingId: bookingId,
      documentId: document.id!,
      token: '',
    );

    if (!context.mounted) {
      return;
    }

    if (result.success) {
      await reload();
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ??
              (result.success
                  ? 'Document deleted successfully'
                  : 'Failed to delete document'),
        ),
      ),
    );
  }

  Future<void> replaceDocument({
    required BuildContext context,
    required String endpoint,
    required int bookingId,
    required Document document,
    required Future<void> Function() reload,
  }) async {
    if (document.documentType == null || document.documentType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document type is missing'),
        ),
      );
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (picked == null || picked.files.isEmpty || !context.mounted) {
      return;
    }

    final uploadResult = await _service.uploadDocument(
      endpoint: endpoint,
      bookingId: bookingId,
      file: picked.files.first,
      documentType: document.documentType!,
      token: '',
    );

    if (!context.mounted) {
      return;
    }

    if (!uploadResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uploadResult.message ?? 'Failed to upload replacement document',
          ),
        ),
      );
      return;
    }

    final deleteResult = await _service.deleteDocument(
      endpoint: endpoint,
      bookingId: bookingId,
      documentId: document.id!,
      token: '',
    );

    if (!context.mounted) {
      return;
    }

    if (deleteResult.success) {
      await reload();
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleteResult.success
              ? 'Document replaced successfully'
              : (deleteResult.message ?? 'Failed to replace document'),
        ),
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> attachDocument({
    required String endpoint,
    required int bookingId,
    required String token,
    required PlatformFile file,
    required String documentType,
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

      final Map<String, dynamic> data =
          response.body.isNotEmpty ? json.decode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data['document'] ?? data,
          message: data['message'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: data['message'] ?? 'Failed to attach document',
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Connection error. Please check your internet connection.',
        errors: [e.toString()],
      );
    } on HttpException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: e.message,
        errors: [e.toString()],
      );
    } on FormatException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Server response error. Please try again.',
        errors: [e.toString()],
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error attaching document: $e',
        errors: [e.toString()],
      );
    }
  }
}
