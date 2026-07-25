import 'package:file_picker/file_picker.dart';

class RequiredDocument {
  final String title;
  final String description;
  final String documentType;

  PlatformFile? file;
  bool isUploading;

  RequiredDocument({
    required this.title,
    required this.description,
    required this.documentType,
    this.file,
    this.isUploading = false,
  });
}
