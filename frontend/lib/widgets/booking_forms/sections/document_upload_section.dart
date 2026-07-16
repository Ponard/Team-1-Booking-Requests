import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DocumentUploadSection extends StatelessWidget {
  final String title;
  final String description;
  final String selectButtonText;
  final String uploadButtonText;
  final String uploadedButtonText;

  final PlatformFile? file;
  final bool isUploading;
  final bool isUploaded;

  final VoidCallback onPick;
  final VoidCallback onUpload;

  const DocumentUploadSection({
    super.key,
    required this.title,
    required this.description,
    this.selectButtonText = "Select Document",
    this.uploadButtonText = "Upload",
    this.uploadedButtonText = "Uploaded Successfully",
    required this.file,
    required this.isUploading,
    required this.isUploaded,
    required this.onPick,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isUploading ? null : onPick,
          icon: const Icon(Icons.attach_file),
          label: Text(
            file?.name ?? selectButtonText,
            overflow: TextOverflow.ellipsis,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                file != null ? Colors.green[100] : Colors.grey[200],
            foregroundColor: Colors.black87,
          ),
        ),
        if (file != null) ...[
          const SizedBox(height: 12),
          isUploading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Uploading...'),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: isUploaded ? null : onUpload,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(
                    isUploaded ? uploadedButtonText : uploadButtonText,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUploaded ? Colors.green : null,
                    foregroundColor: isUploaded ? Colors.white : null,
                  ),
                ),
        ],
      ],
    );
  }
}
