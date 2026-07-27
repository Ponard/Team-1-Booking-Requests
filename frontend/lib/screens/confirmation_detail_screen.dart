import 'package:diocese_frontend/services/booking_document_manager.dart';
import 'package:diocese_frontend/services/file_service.dart';
import 'package:diocese_frontend/utils/required_document.dart';
import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/document_upload_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/parent_information_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/document.dart';
import '../models/confirmation_booking.dart';
import '../models/note.dart';
import '../providers/auth_provider.dart';
import '../providers/priest_provider.dart';
import '../services/confirmation_service.dart';
import '../config/api_config.dart';
import '../widgets/notes_display.dart';

class ConfirmationDetailScreen extends StatefulWidget {
  final int? confirmationId;
  final bool fromStatusButton;

  const ConfirmationDetailScreen({
    super.key,
    required this.confirmationId,
    this.fromStatusButton = false,
  });

  @override
  State<ConfirmationDetailScreen> createState() =>
      _ConfirmationDetailScreenState();
}

class _ConfirmationDetailScreenState extends State<ConfirmationDetailScreen> {
  final ConfirmationService _confirmationService = ConfirmationService();

  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();
  final _documentManager = BookingDocumentManager();

  bool _isEditMode = false;
  bool _isSaving = false;
  bool _showStatusButtons = true;

  ConfirmationBooking? _booking;

  final TextEditingController _confirmandNameController =
      TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredParishController =
      TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();
  int? _selectedPriestId;
  final TextEditingController _newNoteController = TextEditingController();

  late final List<RequiredDocument> _requiredDocuments = [
    RequiredDocument(
      title: 'Baptismal Certificate *',
      description:
          'Please upload a copy of your baptismal certificate. Accepted formats: PDF, JPG, PNG.',
      documentType: 'baptismal_certificate',
    ),
    RequiredDocument(
      title: 'Birth Certificate *',
      description:
          'Please upload a copy of your birth certificate. Accepted formats: PDF, JPG, PNG.',
      documentType: 'birth_certificate',
    ),
  ];

  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
    _showStatusButtons = !widget.fromStatusButton;
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    if (widget.confirmationId == null || widget.confirmationId == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    final result = await _confirmationService.getConfirmationBookingById(
      token: token,
      id: widget.confirmationId!,
    );

    if (mounted && result.success && result.data != null) {
      final booking = result.data!;
      final status = booking.status.toLowerCase();
      final isEditable = status == 'pending' || status == 'declined';
      setState(() {
        _booking = booking;
        _confirmandNameController.text = booking.confirmandName ?? '';
        _fatherNameController.text = booking.fatherName ?? '';
        _motherNameController.text = booking.motherName ?? '';
        _contactEmailController.text = booking.contactEmail ?? '';
        _contactPhoneController.text = booking.contactPhone ?? '';
        _preferredParishController.text = booking.parishName ?? '';
        _preferredDateController.text =
            booking.preferredDate?.split('T')[0] ?? '';
        _preferredTimeController.text = booking.preferredTimeSlot ?? '';
        _selectedPriestId = booking.priestId;
        _documents = booking.documents ?? [];
      });

      await context.read<PriestProvider>().loadPriestsByParish(
            booking.parishId,
            token: authProvider.token,
          );

      if (!mounted) return;

      if (widget.fromStatusButton && isEditable) {
        setState(() => _isEditMode = true);
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
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

  /// Opens a document by launching its URL
  Future<void> _openDocument(Document doc) => _documentManager.openDocument(
        context: context,
        document: doc,
      );

  Future<void> _deleteDocument(Document doc) => _documentManager.deleteDocument(
        context: context,
        endpoint: ApiConfig.confirmationsEndpoint,
        bookingId: widget.confirmationId!,
        document: doc,
        reload: _loadBooking,
      );

  Future<void> _replaceDocument(Document doc) =>
      _documentManager.replaceDocument(
        context: context,
        endpoint: ApiConfig.confirmationsEndpoint,
        bookingId: widget.confirmationId!,
        document: doc,
        reload: _loadBooking,
      );

  Future<void> _pickDocument(RequiredDocument document) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );

      if (!mounted || result == null) return;

      setState(() {
        document.file = result.files.first;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _uploadDocument(
    RequiredDocument document,
  ) async {
    if (document.file == null || widget.confirmationId == null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (token == null) {
      return;
    }

    setState(() {
      document.isUploading = true;
    });

    try {
      final response = await FileService().uploadFile(
        file: document.file!,
        token: token,
        category: 'confirmation',
        additionalFields: {
          'documentType': document.documentType,
        },
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${document.title} uploaded successfully'),
          ),
        );

        await _loadBooking();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Upload failed'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
        ),
      );
    } finally {
      if (!mounted) {
        setState(() {
          document.isUploading = false;
        });
      }
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
    if (!_validateForm()) return;

    if (widget.confirmationId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Authentication required')));
        }
        return;
      }

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

      final result = await _confirmationService.updateConfirmationBooking(
        token: token,
        id: widget.confirmationId!,
        confirmandName: _confirmandNameController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        motherName: _motherNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim().isEmpty
            ? null
            : _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        preferredDate: _preferredDateController.text,
        preferredTimeSlot: _preferredTimeController.text,
        priestId: _selectedPriestId,
        notes: notesToAdd,
      );

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
      if (!_isEditMode) _showStatusButtons = true;
    });
  }

  void _updateStatus(String status) async {
    if (widget.confirmationId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    final result = await _confirmationService.updateConfirmationStatus(
      token: token,
      id: widget.confirmationId!,
      status: status,
    );

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

  String get _displayStatus {
    if (_booking == null) return 'PENDING';
    final status = _booking!.status.toUpperCase();
    return status;
  }

  bool get _canChangeStatus {
    if (_booking == null) return false;
    final status = _booking!.status.toLowerCase();
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

  String get _actionButtonText {
    if (_booking == null) return 'Approve';
    final status = _booking!.status.toLowerCase();
    if (status == 'pending') return 'Approve';
    if (status == 'approved') return 'Mark as Completed';
    return 'Approve';
  }

  Future<void> _resubmitBooking() async {
    if (widget.confirmationId == null) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Not authenticated')));
        setState(() => _isSaving = false);
        return;
      }

      final result = await _confirmationService.resubmitBooking(
        id: widget.confirmationId!,
        token: token,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Booking resubmitted successfully')));
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
    final status = _booking?.status.toLowerCase();
    final canEdit =
        isAdmin || (isOwner && (status == 'pending' || status == 'declined'));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmation Details"),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookingSection(
                    title: "Confirmand Information",
                    children: [
                      BookingTextField(
                        controller: _confirmandNameController,
                        label: "Confirmand Name *",
                        validator: Validators.requiredField,
                        enabled: _isEditMode,
                      ),
                    ],
                  ),

                  ParentInformationSection(
                    fatherController: _fatherNameController,
                    motherController: _motherNameController,
                    enabled: _isEditMode,
                  ),

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
                        label: 'Preferred Confirmation Date *',
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                    children: List.generate(_requiredDocuments.length, (index) {
                      final document = _requiredDocuments[index];

                      return Column(
                        children: [
                          DocumentUploadSection(
                            title: document.title,
                            description: document.description,
                            file: document.file,
                            isUploading: document.isUploading,
                            isUploaded: false,
                            canEdit: _isEditMode,
                            documents: _documents
                                .where((d) =>
                                    d.documentType == document.documentType)
                                .toList(),
                            onPick: () => _pickDocument(document),
                            onUpload: () => _uploadDocument(document),
                            onOpenDocument: _openDocument,
                            onDeleteDocument: _deleteDocument,
                            onReplaceDocument: _replaceDocument,
                          ),
                          if (index < _requiredDocuments.length - 1)
                            const SizedBox(height: 24),
                        ],
                      );
                    }),
                  ),
                  // Notes display
                  if (_booking?.notes != null && _booking!.notes!.isNotEmpty)
                    NotesDisplay(
                      notes: _booking!.notes!.map((note) {
                        if (note is Map) {
                          return Note.fromJson(Map<String, dynamic>.from(note));
                        }
                        return note as Note;
                      }).toList(),
                    ),

                  if (_isEditMode) ...[
                    AdditionalInformationSection(
                      notesController: _newNoteController,
                    ),
                  ],

                  const SizedBox(height: 16),

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
                                icon: const Icon(Icons.refresh),
                                label: const Text('Resubmit Booking'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _resubmitBooking,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildStatusSection(isAdmin, widget.confirmationId ?? 0),
                ],
              ),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildStatusSection(bool isAdmin, int bookingId) {
    if (!isAdmin || _showStatusButtons) return const SizedBox.shrink();

    final displayStatus = _displayStatus;
    final canChangeStatus = _canChangeStatus;
    final actionButtonText = _actionButtonText;
    final status = _booking?.status.toLowerCase();

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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _updateStatus('declined'),
                ),
              ),
            ],
          ),
        ] else if (status == 'approved') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(actionButtonText),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed:
                      canChangeStatus ? () => _updateStatus('completed') : null,
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
    _confirmandNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredParishController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }
}
