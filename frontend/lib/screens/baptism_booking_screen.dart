import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/parish_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/child_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/document_upload_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/parent_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/sponsors_information_section.dart';
import 'package:diocese_frontend/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/baptism_provider.dart';
import '../providers/priest_provider.dart';
import '../services/file_service.dart';
import '../utils/validators.dart';

class BaptismBookingScreen extends StatefulWidget {
  const BaptismBookingScreen({super.key});

  @override
  State<BaptismBookingScreen> createState() => _BaptismBookingScreenState();
}

class _BaptismBookingScreenState extends State<BaptismBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  // --- Controllers ---
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _godparentsController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _preferredParishController =
      TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();

  // Priest selection state
  int? _selectedPriestId;

  // File upload state
  PlatformFile? _birthCertificateFile;
  bool _isUploadingFile = false;
  Map<String, dynamic>? _uploadedFileData;

  @override
  void initState() {
    super.initState();
    // Load parishes for selection
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final parishProvider =
          Provider.of<ParishProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final priestProvider =
          Provider.of<PriestProvider>(context, listen: false);

      parishProvider.clearSelection();
      _populateContactInfo(authProvider);

      await parishProvider.loadParishesByService(
        'baptism',
        token: authProvider.token,
      );

      if (!mounted) return;

      final userParishId = authProvider.currentUser?.preferredParishId;

      if (userParishId != null) {
        final userParish = parishProvider.parishes
            .where((p) => p.id == userParishId)
            .firstOrNull;
        if (userParish != null) {
          parishProvider.selectParish(userParish);
          await priestProvider.loadPriestsByParish(userParishId,
              token: authProvider.token);
        }
      }
    });
  }

  void _populateContactInfo(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user == null) return;

    _contactEmailController.text = user.email;

    if (user.phone != null) {
      _contactPhoneController.text = user.phone!;
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
          _uploadedFileData = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
      }
    }
  }

  Future<void> _uploadBirthCertificate() async {
    if (_birthCertificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file first')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to upload files')));
      return;
    }

    setState(() => _isUploadingFile = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _birthCertificateFile!,
        token: token,
        category: 'baptism',
        additionalFields: {
          'documentType': 'birth_certificate',
        },
      );

      if (response.success && response.data != null) {
        setState(() {
          _uploadedFileData = response.data!['file'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Birth certificate uploaded successfully')));
        }
      } else {
        if (mounted) {
          final errorMsg = response.errors?.isNotEmpty == true
              ? '${response.message}: ${response.errors!.first}'
              : (response.message ?? 'Upload failed');
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
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
    _notesController.dispose();
    _preferredParishController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    super.dispose();
  }

  // --- Modernized Submission Logic ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final baptismProvider =
        Provider.of<BaptismProvider>(context, listen: false);
    final parishProvider = Provider.of<ParishProvider>(context, listen: false);

    // 1. Initial State Requirements Validation
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to submit a booking.")));
      return;
    }

    if (parishProvider.selectedParish == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a parish.")));
      return;
    }

    // Explicit Document Requirement Check
    if (_uploadedFileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please upload the required PSA Birth Certificate.")));
      return;
    }

    String formatDate(String date) {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
      }
      return date;
    }

    // --- Sanitization Block ---
    final cleanChildName = _childNameController.text.trim();
    final cleanDob = formatDate(_dobController.text.trim());
    final cleanFatherName = _fatherNameController.text.trim();
    final cleanMotherName = _motherNameController.text.trim();
    final cleanContactEmail = _contactEmailController.text.trim();
    final cleanContactPhone = _contactPhoneController.text.trim();
    final cleanPreferredDate = formatDate(_preferredDateController.text.trim());
    final cleanPreferredTime = _preferredTimeController.text.trim();
    final cleanNotes = _notesController.text.trim();

    // Safely parse godparents (prevents empty array items)
    List<Map<String, String>> godparents = [];
    if (_godparentsController.text.trim().isNotEmpty) {
      final godparentsList = _godparentsController.text.split(';');
      for (var godparent in godparentsList) {
        if (godparent.trim().isNotEmpty) {
          godparents.add({'fullName': godparent.trim()});
        }
      }
    }

    // Safely parse notes
    List<Map<String, dynamic>>? notesToAdd;
    if (cleanNotes.isNotEmpty) {
      notesToAdd = [
        {
          'author': 'parishioner',
          'content': cleanNotes,
          'authorId': authProvider.currentUser!.id,
        }
      ];
    }

    // 2. Execute API Call
    final success = await baptismProvider.createBaptismBooking(
      parishId: parishProvider.selectedParish!.id!,
      childFullName: cleanChildName,
      dateOfBirth: cleanDob,
      fatherName: cleanFatherName,
      motherName: cleanMotherName,
      contactEmail: cleanContactEmail,
      contactPhone: cleanContactPhone,
      preferredDate: cleanPreferredDate,
      preferredTimeSlot: cleanPreferredTime,
      priestId: _selectedPriestId,
      notes: notesToAdd,
      godparents: godparents.isEmpty ? null : godparents,
      uploadedFile: _uploadedFileData!['filename'],
      filePath: _uploadedFileData!['path'],
      fileUrl: _uploadedFileData!['url'],
      fileSize: _uploadedFileData!['size'],
      mimeType: _uploadedFileData!['mimeType'],
      documentType: 'birth_certificate',
    );

    if (!mounted) return;

    // 3. Handle UI Response
    if (success) {
      _formKey.currentState?.reset();
      Navigator.of(context).pop(true); // Go back
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                baptismProvider.errorMessage ?? "Failed to submit booking.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parishProvider = context.watch<ParishProvider>();
    final hasSelectedParish = parishProvider.selectedParish != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Baptism Booking"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), // Back to Home
        ),
        centerTitle: true,
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
                    const Text(
                      "Fill out the form below to submit your booking request. All fields marked with * are required.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Subject to availability. Parish will confirm your booking and selected priest.",
                      style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Child Info Section
                    ChildInformationSection(
                      childNameController: _childNameController,
                      dobController: _dobController,
                    ),

                    // Parents Info Section
                    ParentInformationSection(
                      fatherController: _fatherNameController,
                      motherController: _motherNameController,
                    ),

                    SponsorsInformationSection(
                      sponsorsController: _godparentsController,
                    ),

                    // Contact Info Section
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
                    ),

                    // Booking Preferences
                    BookingSection(
                      title: 'Booking Preferences',
                      children: [
                        ParishDropdown(
                          onParishChanged: () {
                            setState(() => _selectedPriestId = null);
                          },
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
                          onChanged: hasSelectedParish
                              ? (value) {
                                  setState(() => _selectedPriestId = value);
                                }
                              : null,
                        ),
                      ],
                    ),

                    // Additional Notes
                    AdditionalInformationSection(
                      notesController: _notesController,
                    ),

                    // Document Upload Section
                    BookingSection(
                      title: "Required Documents",
                      children: [
                        DocumentUploadSection(
                          title: "PSA Birth Certificate *",
                          description:
                              "Please upload a copy of the PSA birth certificate. Accepted formats: PDF, JPG, PNG",
                          file: _birthCertificateFile,
                          isUploading: _isUploadingFile,
                          isUploaded: _uploadedFileData != null,
                          onPick: _pickBirthCertificateFile,
                          onUpload: _uploadBirthCertificate,
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- Main Submission Button with State Checking ---
                    Consumer<BaptismProvider>(
                      builder: (context, baptismProvider, _) {
                        return CustomButton(
                          width: double.infinity,
                          text: "Submit Booking",
                          onPressed: _submitForm,
                          isLoading: baptismProvider.isLoading,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
