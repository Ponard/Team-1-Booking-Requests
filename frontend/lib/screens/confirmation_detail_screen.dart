import 'package:diocese_frontend/extensions/build_context_extensions.dart';
import 'package:diocese_frontend/services/booking_document_manager.dart';
import 'package:diocese_frontend/utils/required_document.dart';
import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_detail_title.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/booking_status_actions_section.dart';
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

      // Auto-enable edit mode if user is owner and booking is editable
      final currentUser = authProvider.currentUser;
      final isOwner = booking.userId == currentUser?.id;
      final status = booking.status.toLowerCase();
      final isEditable = status == 'pending' || status == 'declined';
      if (isOwner && isEditable) {
        setState(() => _isEditMode = true);
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
      final response = await _documentManager.attachDocument(
        endpoint: ApiConfig.confirmationsEndpoint,
        bookingId: widget.confirmationId!,
        token: token,
        file: document.file!,
        documentType: document.documentType,
      );

      if (!mounted) return;

      if (response.success) {
        document.file = null;

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
      if (mounted) {
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
      final note = Note.fromInput(
        text: _newNoteController.text,
        currentUser: context.read<AuthProvider>().currentUser,
      );

      final notesToAdd = note == null ? null : [note.toJson()];

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
          await _loadBooking();
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
    });
  }

  Future<void> _updateStatus(String status) async {
    if (widget.confirmationId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    context.handleBookingStatusUpdate(
      _confirmationService.updateConfirmationStatus(
        token: token,
        id: widget.confirmationId!,
        status: status,
      ),
      status,
    );
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
        title:
            BookingDetailTitle(title: 'Confirmation Details', status: status),
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
          else if (canEdit)
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
                        enabled: _isEditMode,
                        controller: _preferredDateController,
                        label: 'Preferred Confirmation Date *',
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        validator: Validators.requiredField,
                      ),
                      BookingTimeField(
                        enabled: _isEditMode,
                        controller: _preferredTimeController,
                        label: 'Preferred Time Slot *',
                        validator: Validators.requiredField,
                      ),
                      PriestDropdown(
                        enabled: _isEditMode,
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
                            const Divider(height: 30),
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

                  if (status == 'declined' && isOwner) ...[
                    const SizedBox(height: 20),
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

                  BookingStatusActionsSection(
                    visible: isAdmin && !_isEditMode,
                    status: _booking?.status ?? 'pending',
                    onUpdateStatus: _updateStatus,
                  )
                ],
              ),
            ),
          ),
        )),
      ),
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
