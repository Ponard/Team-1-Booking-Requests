import 'package:diocese_frontend/config/api_config.dart';
import 'package:diocese_frontend/extensions/build_context_extensions.dart';
import 'package:diocese_frontend/models/note.dart';
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
import 'package:diocese_frontend/widgets/booking_forms/sections/booking_resubmit_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/booking_status_actions_section.dart';
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
  final _documentManager = BookingDocumentManager();

  final BaptismService _baptismService = BaptismService();

  bool _isEditMode = false;
  bool _isSaving = false;

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

  late final List<RequiredDocument> _requiredDocuments = [
    RequiredDocument(
      title: 'Birth Certificate *',
      description:
          'Please upload a copy of your birth certificate. Accepted formats: PDF, JPG, PNG.',
      documentType: 'birth_certificate',
    ),
  ];

  int? _selectedPriestId;

  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
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
      });

      final authProvider = context.read<AuthProvider>();

      if (booking.parishId != null) {
        await context.read<PriestProvider>().loadPriestsByParish(
              booking.parishId!,
              token: authProvider.token,
            );
      }

      // Auto-enable edit mode if user is owner and booking is editable
      final currentUser = authProvider.currentUser;
      final isOwner = booking.userId == currentUser?.id;
      final status = booking.status?.toLowerCase() ?? 'pending';
      final isEditable = status == 'pending' || status == 'declined';
      if (isOwner && isEditable) {
        setState(() => _isEditMode = true);
      }
      // Debug: Print documents count
      // print('=== BAPTISM DETAIL: Documents loaded: ${_documents.length} ===');
      // for (var doc in _documents) {
      //   print(
      //       'Document: id=${doc.id}, type=${doc.documentType}, fileName=${doc.fileName}, fileUrl=${doc.fileUrl}');
      // }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to load booking')));
    }
  }

  Future<void> _openDocument(Document doc) => _documentManager.openDocument(
        context: context,
        document: doc,
      );

  Future<void> _deleteDocument(Document doc) => _documentManager.deleteDocument(
        context: context,
        endpoint: ApiConfig.baptismsEndpoint,
        bookingId: widget.baptismId!,
        document: doc,
        reload: _loadBooking,
      );

  Future<void> _replaceDocument(Document doc) =>
      _documentManager.replaceDocument(
        context: context,
        endpoint: ApiConfig.baptismsEndpoint,
        bookingId: widget.baptismId!,
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
    if (document.file == null || widget.baptismId == null) {
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
        endpoint: ApiConfig.baptismsEndpoint,
        bookingId: widget.baptismId!,
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
      final note = Note.fromInput(
        text: _newNoteController.text,
        currentUser: context.read<AuthProvider>().currentUser,
      );

      final notesToAdd = note == null ? null : [note.toJson()];

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
          await _loadBooking();
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
    });
  }

  Future<void> _updateStatus(String status) async {
    if (widget.baptismId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    context.handleBookingStatusUpdate(
      _baptismService.updateBaptismStatus(
          id: widget.baptismId!, status: status),
      status,
    );
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
        title: BookingDetailTitle(title: 'Baptism Details', status: status),
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
                          enabled: _isEditMode,
                          controller: _preferredDateController,
                          label: 'Preferred Baptism Date *',
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
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
                      children:
                          List.generate(_requiredDocuments.length, (index) {
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

                    // Display existing notes in conversation format
                    if (_booking?.notes != null && _booking!.notes!.isNotEmpty)
                      NotesDisplay(notes: _booking!.notes!),

                    // Add new note field (only in edit mode)
                    if (_isEditMode) ...[
                      AdditionalInformationSection(
                        notesController: _newNoteController,
                      ),
                    ],

                    if (status == 'declined' && isOwner)
                      BookingResubmitSection(
                        onResubmit: _resubmitBooking,
                      ),

                    BookingStatusActionsSection(
                      visible: isAdmin && !_isEditMode,
                      status: _booking?.status ?? 'pending',
                      onUpdateStatus: _updateStatus,
                    )
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
