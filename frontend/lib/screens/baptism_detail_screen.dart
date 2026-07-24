import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/child_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/document_upload_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/parent_information_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/document.dart';
import '../models/baptism_booking.dart';
import '../providers/auth_provider.dart';
import '../providers/priest_provider.dart';
import '../services/baptism_service.dart';
import 'document_preview_screen.dart';
import '../widgets/notes_display.dart';

class BaptismDetailScreen extends StatefulWidget {
  final int? baptismId;
  final bool fromStatusButton;

  const BaptismDetailScreen({
    super.key,
    required this.baptismId,
    this.fromStatusButton = false,
  });

  @override
  State<BaptismDetailScreen> createState() => _BaptismDetailScreenState();
}

class _BaptismDetailScreenState extends State<BaptismDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  final BaptismService _baptismService = BaptismService();
  PlatformFile? _birthCertificateFile;
  bool _isUploading = false;

  bool _isEditMode = false;
  bool _isSaving = false;
  bool _showStatusButtons = true;

  BaptismBooking? _booking;

  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _godparentsController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredParishController =
      TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();
  final TextEditingController _newNoteController = TextEditingController();

  int? _selectedPriestId;

  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
    _showStatusButtons = !widget.fromStatusButton;
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    if (widget.baptismId == null || widget.baptismId == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    final result =
        await _baptismService.getBaptismBookingById(id: widget.baptismId!);
    if (mounted && result.success && result.data != null) {
      final booking = result.data!;
      final status = booking.status?.toLowerCase() ?? 'pending';
      final isEditable = status == 'pending' || status == 'declined';
      setState(() {
        _booking = booking;
        _childNameController.text = booking.childFullName ?? '';
        _dobController.text = booking.dateOfBirth ?? '';
        _fatherNameController.text = booking.fatherName ?? '';
        _motherNameController.text = booking.motherName ?? '';
        _contactEmailController.text = booking.contactEmail ?? '';
        _contactPhoneController.text = booking.contactPhone ?? '';
        _preferredParishController.text = booking.parishName ?? '';
        _preferredDateController.text =
            booking.preferredDate?.split('T')[0] ?? '';
        _preferredTimeController.text = booking.preferredTimeSlot ?? '';
        if (booking.priestId != null) {
          _selectedPriestId = booking.priestId;
        }
        _documents = booking.documents ?? [];
        _birthCertificateFile = null;
      });

      final authProvider = context.read<AuthProvider>();

      if (booking.parishId != null) {
        await context.read<PriestProvider>().loadPriestsByParish(
              booking.parishId!,
              token: authProvider.token,
            );
      }

      // Debug: Print documents count
      // print('=== BAPTISM DETAIL: Documents loaded: ${_documents.length} ===');
      // for (var doc in _documents) {
      //   print(
      //       'Document: id=${doc.id}, type=${doc.documentType}, fileName=${doc.fileName}, fileUrl=${doc.fileUrl}');
      // }
      if (widget.fromStatusButton && isEditable) {
        setState(() => _isEditMode = true);
      } else {
        final currentUser = authProvider.currentUser;
        final isOwner = booking.userId == currentUser?.id;
        if (!widget.fromStatusButton && isOwner && isEditable) {
          setState(() => _isEditMode = true);
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to load booking')));
    }
  }

  Future<void> _pickBirthCertificateFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _birthCertificateFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _uploadBirthCertificate() async {
    if (_birthCertificateFile == null || widget.baptismId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to upload files')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final result = await _baptismService.attachDocumentToBooking(
      bookingId: widget.baptismId!,
      token: token,
      file: _birthCertificateFile!,
      documentType: 'birth_certificate',
    );

    setState(() => _isUploading = false);

    if (result.success) {
      await _loadBooking();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Birth certificate uploaded successfully'
              : (result.message ?? 'Upload failed'),
        ),
      ),
    );
  }

  /// Opens a document in the preview screen
  Future<void> _openDocument(Document document) async {
    if (document.fileUrl == null || document.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available')),
      );
      return;
    }

    // Navigate to document preview screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPreviewScreen(document: document),
      ),
    );
  }

  Future<void> _deleteDocument(Document doc) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
            'Are you sure you want to delete "${doc.fileName ?? 'this document'}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm != true) return;

    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }

    final result = await _baptismService.deleteDocument(
      bookingId: widget.baptismId!,
      documentId: doc.id!,
    );

    if (!mounted) return;

    if (result.success) {
      await _loadBooking(); // Refresh
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Document deleted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message ?? 'Failed to delete document')));
    }
  }

  Future<void> _replaceDocument(Document doc) async {
    // Pick new file
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final newFile = result.files.first;

    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }

    // Upload new document
    final uploadResult = await _baptismService.attachDocumentToBooking(
      bookingId: widget.baptismId!,
      token: token,
      file: newFile,
      documentType: doc.documentType,
    );

    if (!mounted) return;

    if (uploadResult.success) {
      // Delete old document
      final deleteResult = await _baptismService.deleteDocument(
        bookingId: widget.baptismId!,
        documentId: doc.id!,
      );
      if (!mounted) return;
      if (!deleteResult.success) {
        // Log but continue
        // print('Failed to delete old document: ${deleteResult.message}');
      }
      await _loadBooking();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uploadResult.message ?? 'Document replaced')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(uploadResult.message ?? 'Failed to upload new document')));
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    // print('=== SAVE BUTTON CLICKED ===');

    if (!_validateForm()) {
      // print('Validation failed');
      return;
    }

    if (widget.baptismId == null) {
      // print('No baptism ID');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    // print('Starting save...');
    setState(() => _isSaving = true);

    try {
      // Prepare notes array if a new note was added
      List<Map<String, dynamic>>? notesToAdd;
      if (_newNoteController.text.trim().isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        final isParishioner = currentUser?.role == 'parishioner';
        notesToAdd = [
          {
            'author': isParishioner ? 'parishioner' : 'admin',
            'content': _newNoteController.text.trim(),
            'authorId': currentUser?.id,
          }
        ];
      }

      final result = await _baptismService.updateBaptismBooking(
        id: widget.baptismId!,
        childFullName: _childNameController.text.trim(),
        dateOfBirth: _dobController.text,
        fatherName: _fatherNameController.text.trim(),
        motherName: _motherNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        preferredDate: _preferredDateController.text,
        preferredTimeSlot: _preferredTimeController.text,
        priestId: _selectedPriestId,
        notes: notesToAdd,
      );

      // print('Save result: ${result.success} - ${result.message}');

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking updated successfully')));
          _newNoteController.clear();
          _toggleEditMode();
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message ?? 'Failed')));
        }
      }
    } catch (e) {
      // print('Error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _showStatusButtons = true;
        _birthCertificateFile = null;
      }
    });
  }

  void _updateStatus(String status) async {
    if (widget.baptismId == null) return;

    final result = await _baptismService.updateBaptismStatus(
        id: widget.baptismId!, status: status);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Booking marked as $status')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message ?? 'Failed')));
      }
    }
  }

  /// Computes the display status based on current status and scheduled date
  String get _displayStatus {
    if (_booking == null) return 'PENDING';
    final status = (_booking?.status?.toUpperCase() ?? 'PENDING');
    return status;
  }

  /// Determines if the action button should be enabled
  /// - For pending status: always true (can approve/decline)
  /// - For approved status: true only if event date has passed (can mark completed)
  /// - For other statuses: false
  bool get _canChangeStatus {
    if (_booking == null) return false;
    final status = _booking!.status?.toLowerCase();
    if (status == 'pending') {
      return true;
    } else if (status == 'approved') {
      final scheduledDate = _booking!.preferredDate;
      if (scheduledDate != null && scheduledDate.isNotEmpty) {
        try {
          final now = DateTime.now();
          final bookingDate = DateTime.parse(scheduledDate);
          final today = DateTime(now.year, now.month, now.day);
          final eventDate =
              DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          return eventDate.isBefore(today);
        } catch (e) {
          return false;
        }
      }
      return false;
    }
    return false;
  }

  /// Returns the appropriate action button text based on status
  String get _actionButtonText {
    if (_booking == null) return 'Approve';
    final status = _booking!.status?.toLowerCase();
    if (status == 'pending') return 'Approve';
    if (status == 'approved') return 'Mark as Completed';
    return 'Approve';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final role = currentUser?.role;
    final isAdmin = [
      'parish_admin',
      'parish_staff',
      'diocese_admin',
      'diocese_staff'
    ].contains(role);
    final isOwner = _booking?.userId == currentUser?.id;
    final status = _booking?.status?.toLowerCase();
    final canEdit =
        isAdmin || (isOwner && (status == 'pending' || status == 'declined'));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Baptism Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: Icon(_isSaving ? Icons.edit : Icons.save),
              tooltip: _isSaving ? 'Saving...' : 'Save changes',
              color: _isSaving ? Colors.orange : null,
              onPressed: _saveChanges,
            )
          else if (!_showStatusButtons && canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: _toggleEditMode,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: BookingFormScope(
              controller: _bookingFormController,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ChildInformationSection(
                      childNameController: _childNameController,
                      dobController: _dobController,
                      enabled: _isEditMode,
                    ),

                    ParentInformationSection(
                      fatherController: _fatherNameController,
                      motherController: _motherNameController,
                      enabled: _isEditMode,
                    ),

                    // TODO: godparents field
                    // SponsorsInformationSection(
                    //   sponsorsController: _godparentsController,
                    // ),

                    ContactInformationSection(
                      emailController: _contactEmailController,
                      phoneController: _contactPhoneController,
                      emailValidator: (value) {
                        return Validators.requiredField(value) ??
                            Validators.emailValidator(value);
                      },
                      phoneValidator: (value) {
                        return Validators.requiredField(value) ??
                            Validators.phoneValidator(value);
                      },
                      enabled: _isEditMode,
                    ),

                    BookingSection(
                      title: 'Booking Preferences',
                      children: [
                        BookingTextField(
                          enabled: false,
                          controller: _preferredParishController,
                          label: "Preferred Parish *",
                        ),
                        BookingDateField(
                          controller: _preferredDateController,
                          label: 'Preferred Baptism Date *',
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          validator: Validators.requiredField,
                        ),
                        BookingTimeField(
                          controller: _preferredTimeController,
                          label: 'Preferred Time Slot *',
                          validator: Validators.requiredField,
                        ),
                        PriestDropdown(
                          selectedPriestId: _selectedPriestId,
                          onChanged: (value) {
                            setState(() => _selectedPriestId = value);
                          },
                        ),
                      ],
                    ),

                    BookingSection(
                      title: 'Required Documents',
                      children: [
                        DocumentUploadSection(
                          title: 'PSA Birth Certificate *',
                          description:
                              "Please upload a copy of the PSA birth certificate. Accepted formats: PDF, JPG, PNG",
                          file: _birthCertificateFile,
                          isUploading: _isUploading,
                          isUploaded: false,
                          documents: _documents,
                          canEdit: _isEditMode,
                          onPick: _pickBirthCertificateFile,
                          onUpload: _uploadBirthCertificate,
                          onOpenDocument: _openDocument,
                          onDeleteDocument: _deleteDocument,
                          onReplaceDocument: _replaceDocument,
                        ),
                      ],
                    ),

                    // Display existing notes in conversation format
                    if (_booking?.notes != null && _booking!.notes!.isNotEmpty)
                      NotesDisplay(notes: _booking!.notes!),

                    // Add new note field (only in edit mode)
                    if (_isEditMode) ...[
                      AdditionalInformationSection(
                        notesController: _newNoteController,
                      ),
                    ],

                    const SizedBox(height: 20),
                    if (status == 'declined' && isOwner) ...[
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your booking was declined. Please make the necessary changes and resubmit.',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.refresh),
                                  label: Text(_isSaving
                                      ? 'Resubmitting...'
                                      : 'Resubmit Booking'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed:
                                      _isSaving ? null : _resubmitBooking,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildStatusSection(isAdmin, widget.baptismId ?? 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resubmitBooking() async {
    if (widget.baptismId == null) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      final isParishioner = currentUser?.role == 'parishioner';

      List<Map<String, dynamic>>? notes;
      if (_newNoteController.text.trim().isNotEmpty) {
        notes = [
          {
            'author': isParishioner ? 'parishioner' : 'admin',
            'content': _newNoteController.text.trim(),
            'authorId': currentUser?.id,
          }
        ];
      }

      final result = await _baptismService.resubmitBooking(
        id: widget.baptismId!,
        notes: notes,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Booking resubmitted successfully')));
          _newNoteController.clear();
          await _loadBooking();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message ?? 'Failed to resubmit')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildStatusSection(bool isAdmin, int bookingId) {
    if (!isAdmin || _showStatusButtons) return const SizedBox.shrink();

    // 1. Fetch user role
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserRole = authProvider.currentUser?.role;

    // 2. Restrict approval permissions (block parish_staff)
    final canApprove = currentUserRole == 'priest' ||
        currentUserRole == 'parish_admin' ||
        currentUserRole == 'diocese_admin' ||
        currentUserRole == 'diocese_staff';

    final displayStatus = _displayStatus;
    final canChangeStatus = _canChangeStatus;
    final actionButtonText = _actionButtonText;
    final status = _booking?.status?.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Text(
                  displayStatus,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        if (status == 'pending') ...[
          // 3. Enforce Role Hierarchy UI logic
          if (canApprove)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _updateStatus('approved'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Decline'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _updateStatus('declined'),
                  ),
                ),
              ],
            )
          else
            // Fallback UI for parish_staff
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Pending Priest Approval",
                style: TextStyle(
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500),
              ),
            ),
        ] else if (status == 'approved') ...[
          if (canApprove)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(actionButtonText),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: canChangeStatus
                        ? () => _updateStatus('completed')
                        : null,
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _dobController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _godparentsController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredParishController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }
}
