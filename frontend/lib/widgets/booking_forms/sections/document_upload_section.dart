import 'package:diocese_frontend/models/document.dart';
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

  final List<Document> documents;

  final bool canEdit;
  final bool showVerificationStatus;

  final VoidCallback onPick;
  final VoidCallback onUpload;

  final ValueChanged<Document>? onOpenDocument;
  final ValueChanged<Document>? onDeleteDocument;
  final ValueChanged<Document>? onReplaceDocument;

  const DocumentUploadSection({
    super.key,
    required this.title,
    required this.description,
    required this.file,
    required this.isUploading,
    required this.isUploaded,
    required this.onPick,
    required this.onUpload,
    this.selectButtonText = 'Select Document',
    this.uploadButtonText = 'Upload',
    this.uploadedButtonText = 'Uploaded Successfully',
    this.documents = const [],
    this.canEdit = true,
    this.showVerificationStatus = true,
    this.onOpenDocument,
    this.onDeleteDocument,
    this.onReplaceDocument,
  });

  Icon _documentIcon(Document doc) {
    final filename = (doc.fileName ?? '').toLowerCase();

    if (filename.endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    }

    if (filename.endsWith('.jpg') ||
        filename.endsWith('.jpeg') ||
        filename.endsWith('.png')) {
      return const Icon(Icons.image, color: Colors.blue);
    }

    return const Icon(Icons.insert_drive_file, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingDocuments = documents.isNotEmpty;

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
        if (hasExistingDocuments) ...[
          const SizedBox(height: 16),
          const Text(
            'Uploaded Document',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...documents.map(
            (doc) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _documentIcon(doc),
              title: Text(
                doc.fileName ?? 'Document',
              ),
              subtitle: Text(
                doc.documentType?.toUpperCase().replaceAll('_', ' ') ?? '',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showVerificationStatus)
                    if (doc.isVerified == true)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      )
                    else
                      const Icon(
                        Icons.pending,
                        color: Colors.orange,
                        size: 20,
                      ),
                  if (onOpenDocument != null ||
                      onDeleteDocument != null ||
                      onReplaceDocument != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            onOpenDocument?.call(doc);
                            break;
                          case 'delete':
                            onDeleteDocument?.call(doc);
                            break;
                          case 'replace':
                            onReplaceDocument?.call(doc);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        if (onOpenDocument != null)
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View'),
                          ),
                        if (canEdit && onReplaceDocument != null)
                          const PopupMenuItem(
                            value: 'replace',
                            child: Text('Replace'),
                          ),
                        if (canEdit && onDeleteDocument != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ],
                    ),
                ],
              ),
              onTap: onOpenDocument == null ? null : () => onOpenDocument!(doc),
            ),
          ),
        ],
        if (canEdit) ...[
          if (!hasExistingDocuments) ...[
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
          ],
          if (file != null) ...[
            const SizedBox(height: 12),
            if (isUploading)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Uploading...'),
                ],
              )
            else
              ElevatedButton.icon(
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
      ],
    );
  }
}
