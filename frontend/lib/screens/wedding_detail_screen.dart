import 'package:diocese_frontend/constants/booking_approval_stages.dart';
import 'package:diocese_frontend/extensions/build_context_extensions.dart';
import 'package:diocese_frontend/utils/required_document.dart';
import 'package:diocese_frontend/services/booking_document_manager.dart';
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
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/couple_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/document_upload_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/priest_provider.dart';
import '../services/wedding_service.dart';
import '../models/document.dart';
import '../models/wedding_booking.dart';
import '../models/note.dart';
import '../config/api_config.dart';
import '../widgets/notes_display.dart';

class WeddingDetailScreen extends StatefulWidget {
  final int? weddingId;
  final bool fromStatusButton;

  const WeddingDetailScreen({
    super.key,
    required this.weddingId,
    this.fromStatusButton = false,
  });

  @override
  State<WeddingDetailScreen> createState() => _WeddingDetailScreenState();
}

class _WeddingDetailScreenState extends State<WeddingDetailScreen> {
  final WeddingService _weddingService = WeddingService();
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();
  final _documentManager = BookingDocumentManager();

  bool _isEditMode = false;
  bool _isSaving = false;

  WeddingBooking? _booking;

  // Controllers
  final TextEditingController _groomNameController = TextEditingController();
  final TextEditingController _brideNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredParishController =
      TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();
  final TextEditingController _seminarScheduleController =
      TextEditingController();
  int? _selectedPriestId;
  final TextEditingController _newNoteController = TextEditingController();

  // Document files and upload data
  late final List<RequiredDocument> _requiredDocuments = [
    RequiredDocument(
      title: 'CENOMAR *',
      description:
          'Please upload a copy of your CENOMAR. Accepted formats: PDF, JPG, PNG.',
      documentType: 'cenomar',
    ),
    RequiredDocument(
      title: 'Birth Certificate *',
      description:
          'Please upload a copy of your birth certificate. Accepted formats: PDF, JPG, PNG.',
      documentType: 'birth_certificate',
    ),
    RequiredDocument(
      title: 'Baptismal Certificate *',
      description:
          'Please upload a copy of your baptismal certificate. Accepted formats: PDF, JPG, PNG.',
      documentType: 'baptismal_certificate',
    ),
    RequiredDocument(
      title: 'Confirmation Certificate *',
      description:
          'Please upload a copy of your confirmation certificate. Accepted formats: PDF, JPG, PNG.',
      documentType: 'confirmation_certificate',
    ),
  ];

  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _groomNameController.dispose();
    _brideNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredParishController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _seminarScheduleController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    if (widget.weddingId == null || widget.weddingId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid booking ID')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view booking')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final result = await _weddingService.getWeddingBookingById(
      token: token,
      id: widget.weddingId!,
    );

    if (mounted && result.success && result.data != null) {
      final booking = result.data!;
      setState(() {
        _booking = booking;
        _groomNameController.text = booking.groomFullName ?? '';
        _brideNameController.text = booking.brideFullName ?? '';
        _contactEmailController.text = booking.contactEmail ?? '';
        _contactPhoneController.text = booking.contactPhone ?? '';
        _preferredParishController.text = booking.parishName ?? '';
        _preferredDateController.text =
            booking.preferredDate?.split('T')[0] ?? '';
        _preferredTimeController.text = booking.preferredTimeSlot ?? '';
        _seminarScheduleController.text = booking.seminarSchedule ?? '';
        if (booking.priestId != null) {
          _selectedPriestId = booking.priestId;
        }
        _documents = booking.documents ?? [];
      });

      await context.read<PriestProvider>().loadPriestsByParish(
            booking.parishId,
            token: authProvider.token,
          );

      if (!mounted) return;

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
        SnackBar(content: Text(result.message ?? 'Failed to load booking')),
      );
      Navigator.pop(context);
    }
  }

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
    if (document.file == null || widget.weddingId == null) {
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
        endpoint: ApiConfig.weddingsEndpoint,
        bookingId: widget.weddingId!,
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

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return;
    }

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to update booking')),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    // Prepare notes array if a new note was added
    final note = Note.fromInput(
      text: _newNoteController.text,
      currentUser: context.read<AuthProvider>().currentUser,
    );

    final notesToAdd = note == null ? null : [note.toJson()];

    final result = await _weddingService.updateWeddingBooking(
      token: token,
      id: widget.weddingId!,
      groomFullName: _groomNameController.text.trim(),
      brideFullName: _brideNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      preferredDate: _preferredDateController.text.trim(),
      preferredTimeSlot: _preferredTimeController.text.trim(),
      seminarSchedule: _seminarScheduleController.text.trim(),
      priestId: _selectedPriestId,
      notes: notesToAdd,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ?? 'Booking updated successfully')),
        );
        _newNoteController.clear();
        setState(() => _isEditMode = false);
        await _loadBooking(); // Reload to show updated data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to update booking')),
        );
      }
    }
  }

  Future<void> _resubmitBooking() async {
    if (widget.weddingId == null) return;

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

      final result = await _weddingService.resubmitBooking(
        id: widget.weddingId!,
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

  Future<void> _openDocument(Document doc) => _documentManager.openDocument(
        context: context,
        document: doc,
      );

  Future<void> _deleteDocument(Document doc) => _documentManager.deleteDocument(
        context: context,
        endpoint: ApiConfig.weddingsEndpoint,
        bookingId: widget.weddingId!,
        document: doc,
        reload: _loadBooking,
      );

  Future<void> _replaceDocument(Document doc) =>
      _documentManager.replaceDocument(
        context: context,
        endpoint: ApiConfig.weddingsEndpoint,
        bookingId: widget.weddingId!,
        document: doc,
        reload: _loadBooking,
      );

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
        title: BookingDetailTitle(title: 'Wedding Details', status: status),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: Icon(_isSaving ? Icons.edit : Icons.save),
              tooltip: _isSaving ? 'Saving...' : 'Save changes',
              color: _isSaving ? Colors.orange : null,
              onPressed: _saveBooking,
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
                    // Status Card

                    CoupleInformationSection(
                      groomController: _groomNameController,
                      brideController: _brideNameController,
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
                          label: 'Preferred Wedding Date *',
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
                        BookingDateField(
                          enabled: _isEditMode,
                          controller: _seminarScheduleController,
                          label: 'Seminar Schedule *',
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 730)),
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

                    // Documents Section
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

                    // Notes display
                    if (_booking?.notes != null && _booking!.notes!.isNotEmpty)
                      NotesDisplay(
                        notes: _booking!.notes!.map((note) {
                          if (note is Map) {
                            return Note.fromJson(
                                Map<String, dynamic>.from(note));
                          }
                          return note as Note;
                        }).toList(),
                      ),

                    if (_isEditMode) ...[
                      AdditionalInformationSection(
                        notesController: _newNoteController,
                      ),
                    ],

                    if (status == 'declined' && isOwner)
                      BookingResubmitSection(
                        onResubmit: _resubmitBooking,
                      ),

                    if (!_isEditMode)
                      BookingStatusActionsSection(
                        status: _booking?.status ?? 'pending',
                        approvalStage: _booking?.approvalStage ??
                            BookingApprovalStages.staff,
                        role: currentUser?.role,
                        onUpdateStatus: _updateStatus,
                        onForwardToPriest: _forwardToPriest,
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

  Future<void> _updateStatus(String status) async {
    if (widget.weddingId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    context.handleBookingStatusUpdate(
      _weddingService.updateWeddingStatus(
        token: token,
        id: widget.weddingId!,
        status: status,
      ),
      status,
    );
  }

  Future<void> _forwardToPriest() async {
    if (!mounted) return;

    try {
      await _weddingService.forwardToPriest(id: widget.weddingId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking forwarded to the priest successfully.'),
        ),
      );

      await _loadBooking();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
