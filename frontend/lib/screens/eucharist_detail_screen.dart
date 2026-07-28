import 'package:diocese_frontend/services/booking_document_manager.dart';
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

import '../providers/auth_provider.dart';
import '../providers/priest_provider.dart';
import '../services/eucharist_service.dart';
import '../services/file_service.dart';
import '../models/document.dart';
import '../models/eucharist_booking.dart';
import '../models/note.dart';
import '../config/api_config.dart';
import '../widgets/notes_display.dart';

class EucharistDetailScreen extends StatefulWidget {
  final int? eucharistId;
  final bool fromStatusButton;

  const EucharistDetailScreen({
    super.key,
    required this.eucharistId,
    this.fromStatusButton = false,
  });

  @override
  State<EucharistDetailScreen> createState() => _EucharistDetailScreenState();
}

class _EucharistDetailScreenState extends State<EucharistDetailScreen> {
  final EucharistService _eucharistService = EucharistService();
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();
  final _documentManager = BookingDocumentManager();

  bool _isEditMode = false;
  bool _isSaving = false;
  bool _showStatusButtons = true;

  EucharistBooking? _booking;

  // Controllers
  final TextEditingController _communicantNameController =
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

  // Document files and upload data
  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
    _showStatusButtons = !widget.fromStatusButton;
    _loadBooking();
  }

  @override
  void dispose() {
    _communicantNameController.dispose();
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

  Future<void> _loadBooking() async {
    if (widget.eucharistId == null || widget.eucharistId == 0) {
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

    final result = await _eucharistService.getEucharistBookingById(
      token: token,
      id: widget.eucharistId!,
    );

    if (mounted && result.success && result.data != null) {
      final booking = result.data!;
      final status = booking.status.toLowerCase();
      final isEditable = status == 'pending' || status == 'declined';
      setState(() {
        _booking = booking;
        _communicantNameController.text = booking.communicantName ?? '';
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
        final currentUser = authProvider.currentUser;
        final isOwner = booking.userId == currentUser?.id;
        if (!widget.fromStatusButton && isOwner && isEditable) {
          setState(() => _isEditMode = true);
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to load booking')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _openDocument(Document doc) => _documentManager.openDocument(
        context: context,
        document: doc,
      );

  Future<void> _deleteDocument(Document doc) => _documentManager.deleteDocument(
        context: context,
        endpoint: ApiConfig.confirmationsEndpoint,
        bookingId: widget.eucharistId!,
        document: doc,
        reload: _loadBooking,
      );

  Future<void> _replaceDocument(Document doc) =>
      _documentManager.replaceDocument(
        context: context,
        endpoint: ApiConfig.confirmationsEndpoint,
        bookingId: widget.eucharistId!,
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
    if (document.file == null || widget.eucharistId == null) {
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
        category: 'eucharist',
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

    final result = await _eucharistService.updateEucharistBooking(
      token: token,
      id: widget.eucharistId!,
      communicantName: _communicantNameController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      motherName: _motherNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      preferredDate: _preferredDateController.text.trim(),
      preferredTimeSlot: _preferredTimeController.text.trim(),
      priestId: _selectedPriestId,
      notes: notesToAdd,
    );

    //QA FIX: Check if the widget is still mounted BEFORE calling setState
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ?? 'Booking updated successfully')),
        );
        _newNoteController.clear();
        setState(() => _isEditMode = false);
        await _loadBooking();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to update booking')),
        );
      }
    }
  }

  // Future<void> _updateStatus(String status) async {
  //   if (widget.eucharistId == null) return;

  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //   final token = authProvider.token;
  //   if (token == null) return;

  //   final result = await _eucharistService.updateEucharistStatus(
  //     token: token,
  //     id: widget.eucharistId!,
  //     status: status,
  //   );

  //   if (mounted) {
  //     if (result.success) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Booking marked as $status')),
  //       );
  //       Navigator.pop(context, true);
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(result.message ?? 'Failed')),
  //       );
  //     }
  //   }
  // }

  Future<void> _deleteBooking() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to delete booking')),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    final result = await _eucharistService.deleteEucharistBooking(
      token: token,
      id: widget.eucharistId!,
    );

    //QA FIX: Check if the widget is still mounted BEFORE calling setState

    setState(() => _isSaving = false);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to cancel booking')),
        );
      }
    }
  }

  Future<void> _resubmitBooking() async {
    if (widget.eucharistId == null) return;

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

      final result = await _eucharistService.resubmitBooking(
        id: widget.eucharistId!,
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

  String get _displayStatus {
    if (_booking == null) return 'PENDING';
    final status = (_booking?.status.toUpperCase() ?? 'PENDING');
    return status;
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
    final effectiveStatus = _displayStatus.toLowerCase();
    final canDelete = isAdmin || (isOwner && effectiveStatus != 'approved');

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _booking != null ? 'First Communion' : 'First Communion Details'),
        actions: [
          if (_booking != null && !_isEditMode && _showStatusButtons)
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditMode = true),
                tooltip: 'Edit',
              ),
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
                    // Card(
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(16.0),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //       children: [
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             const Text(
                    //               'Status',
                    //               style: TextStyle(
                    //                   fontSize: 12, color: Colors.grey),
                    //             ),
                    //             const SizedBox(height: 4),
                    //             Container(
                    //               padding: const EdgeInsets.symmetric(
                    //                   horizontal: 12, vertical: 6),
                    //               decoration: BoxDecoration(
                    //                 color: _getStatusColor(
                    //                         _booking!.status.toLowerCase())
                    //                     .withValues(alpha: 0.2),
                    //                 borderRadius: BorderRadius.circular(12),
                    //               ),
                    //               child: Text(
                    //                 _displayStatus,
                    //                 style: TextStyle(
                    //                   color: _getStatusColor(
                    //                       _displayStatus.toLowerCase()),
                    //                   fontWeight: FontWeight.bold,
                    //                 ),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //         if (!_showStatusButtons && isAdmin)
                    //           Row(
                    //             children: [
                    //               if (_booking!.status.toLowerCase() ==
                    //                   'pending')
                    //                 ElevatedButton(
                    //                   onPressed: () =>
                    //                       _updateStatus('declined'),
                    //                   style: ElevatedButton.styleFrom(
                    //                       backgroundColor: Colors.red),
                    //                   child: const Text('Decline'),
                    //                 ),
                    //               if (_booking!.status.toLowerCase() ==
                    //                   'pending')
                    //                 const SizedBox(width: 8),
                    //               if (_booking!.status.toLowerCase() ==
                    //                   'pending')
                    //                 ElevatedButton(
                    //                   onPressed: () =>
                    //                       _updateStatus('approved'),
                    //                   style: ElevatedButton.styleFrom(
                    //                       backgroundColor: Colors.green),
                    //                   child: const Text('Approve'),
                    //                 ),
                    //             ],
                    //           ),
                    //       ],
                    //     ),
                    //   ),
                    // ),

                    // Communicant Name
                    BookingSection(
                      title: "Communicant Information",
                      children: [
                        BookingTextField(
                          controller: _communicantNameController,
                          label: "Communicant Name *",
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
                    ],

                    // Save/Cancel Buttons
                    if (_isEditMode)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveBooking,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => setState(() => _isEditMode = false),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),

                    // Delete Button (owners can delete any non-approved booking)
                    if (_isEditMode && _booking != null && canDelete)
                      const SizedBox(height: 16),
                    if (_isEditMode && _booking != null && canDelete)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _deleteBooking,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel Booking'),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Color _getStatusColor(String? status) {
  //   switch (status?.toLowerCase()) {
  //     case 'approved':
  //       return Colors.green;
  //     case 'declined':
  //     case 'rejected':
  //       return Colors.red;
  //     case 'completed':
  //       return Colors.blue;
  //     default:
  //       return Colors.orange;
  //   }
  // }
}
