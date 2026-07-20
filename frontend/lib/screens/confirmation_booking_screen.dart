import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/parish_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
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
import '../providers/confirmation_provider.dart';
import '../providers/priest_provider.dart';
import '../services/file_service.dart';
import '../utils/validators.dart';

class ConfirmationBookingScreen extends StatefulWidget {
  const ConfirmationBookingScreen({super.key});

  @override
  State<ConfirmationBookingScreen> createState() =>
      _ConfirmationBookingScreenState();
}

class _ConfirmationBookingScreenState extends State<ConfirmationBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  // Controllers
  final TextEditingController _confirmandNameController =
      TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _sponsorController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Priest selection state
  int? _selectedPriestId;

  // File
  PlatformFile? _baptismalCertificate;
  bool _isUploadingBaptismal = false;
  Map<String, dynamic>? _uploadedBaptismalData;

  PlatformFile? _birthCertificate;
  bool _isUploadingBirth = false;
  Map<String, dynamic>? _uploadedBirthData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final parishProvider =
          Provider.of<ParishProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final priestProvider =
          Provider.of<PriestProvider>(context, listen: false);

      parishProvider.clearSelection();
      await parishProvider.loadParishesByService(
        'confirmation',
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

  @override
  void dispose() {
    _confirmandNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _sponsorController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickBaptismalCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _baptismalCertificate = result.files.first;
          _uploadedBaptismalData = null;
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

  Future<void> _uploadBaptismalCertificate() async {
    if (_baptismalCertificate == null) {
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

    setState(() {
      _isUploadingBaptismal = true;
    });

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _baptismalCertificate!,
        token: token,
        category: 'confirmation',
        additionalFields: {
          'documentType': 'baptismal_certificate',
        },
      );

      if (response.success && response.data != null) {
        setState(() {
          _uploadedBaptismalData = response.data!['file'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Baptismal certificate uploaded successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Upload failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingBaptismal = false;
        });
      }
    }
  }

  // Birth certificate pick and upload
  Future<void> _pickBirthCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _birthCertificate = result.files.first;
          _uploadedBirthData = null;
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
    if (_birthCertificate == null) {
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

    setState(() {
      _isUploadingBirth = true;
    });

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _birthCertificate!,
        token: token,
        category: 'confirmation',
        additionalFields: {
          'documentType': 'birth_certificate',
        },
      );

      if (response.success && response.data != null) {
        setState(() {
          _uploadedBirthData = response.data!['file'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Birth certificate uploaded successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Upload failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingBirth = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirmationProvider =
        Provider.of<ConfirmationProvider>(context, listen: false);
    final parishProvider = Provider.of<ParishProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to submit a booking.")),
      );
      return;
    }

    if (parishProvider.selectedParish == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a parish.")),
      );
      return;
    }

    // Validate that both required documents are uploaded
    if (_uploadedBaptismalData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please upload the required Baptismal Certificate.")),
      );
      return;
    }
    if (_uploadedBirthData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please upload the required Birth Certificate.")),
      );
      return;
    }

    String formatDate(String date) {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
      }
      return date;
    }

    // Prepare notes array if a note was added
    List<Map<String, dynamic>>? notesToAdd;
    if (_notesController.text.trim().isNotEmpty) {
      notesToAdd = [
        {
          'author': 'parishioner',
          'content': _notesController.text.trim(),
          'authorId': authProvider.currentUser!.id,
        }
      ];
    }

    final success = await confirmationProvider.createConfirmationBooking(
      token: authProvider.token!,
      parishId: parishProvider.selectedParish!.id!,
      confirmandName: _confirmandNameController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      motherName: _motherNameController.text.trim(),

      //add the missing sponsor payload
      sponsorName: _sponsorController.text.trim(),

      contactEmail: _contactEmailController.text.trim().isNotEmpty
          ? _contactEmailController.text.trim()
          : authProvider.currentUser!.email,
      contactPhone: _contactPhoneController.text.trim(),

      //added the trim method to date and time
      preferredDate: formatDate(_preferredDateController.text.trim()),
      preferredTimeSlot: _preferredTimeController.text.trim(),

      priestId: _selectedPriestId,
      notes: notesToAdd,
      baptismalCertificate: _uploadedBaptismalData,
      birthCertificate: _uploadedBirthData,
    );

    if (success && mounted) {
      _formKey.currentState?.reset();
      Navigator.of(context).pop(true); // Go back
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(confirmationProvider.errorMessage ??
                "Failed to submit booking.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmation Booking"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirmand
                    BookingSection(
                      title: "Confirmand Information",
                      children: [
                        BookingTextField(
                          controller: _confirmandNameController,
                          label: "Confirmand Name *",
                          validator: Validators.requiredField,
                        ),
                      ],
                    ),

                    // Parent Information
                    ParentInformationSection(
                      fatherController: _fatherNameController,
                      motherController: _motherNameController,
                    ),

                    // Sponsor Information
                    SponsorsInformationSection(
                      sponsorsController: _sponsorController,
                    ),

                    // Contact Information
                    ContactInformationSection(
                      emailController: _contactEmailController,
                      phoneController: _contactPhoneController,
                      emailValidator: Validators.emailValidator,
                      phoneValidator: Validators.phoneValidator,
                    ),

                    // Booking Preferences
                    BookingSection(
                      title: "Booking Preferences",
                      children: [
                        ParishDropdown(
                          onParishChanged: () {
                            setState(() => _selectedPriestId = null);
                          },
                        ),
                        BookingDateField(
                          controller: _preferredDateController,
                          label: "Preferred Confirmation Date *",
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          validator: Validators.requiredField,
                        ),
                        BookingTimeField(
                          controller: _preferredTimeController,
                          label: "Preferred Time Slot *",
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

                    // Required Documents
                    BookingSection(
                      title: "Required Documents",
                      children: [
                        DocumentUploadSection(
                          title: "Baptismal Certificate *",
                          description:
                              "Please upload a copy of the baptismal certificate. Accepted formats: PDF, JPG, PNG",
                          file: _baptismalCertificate,
                          isUploading: _isUploadingBaptismal,
                          isUploaded: _uploadedBaptismalData != null,
                          onPick: _pickBaptismalCertificate,
                          onUpload: _uploadBaptismalCertificate,
                        ),
                        const SizedBox(height: 24),
                        DocumentUploadSection(
                          title: "Birth Certificate *",
                          description:
                              "Please upload a copy of the birth certificate. Accepted formats: PDF, JPG, PNG",
                          file: _birthCertificate,
                          isUploading: _isUploadingBirth,
                          isUploaded: _uploadedBirthData != null,
                          onPick: _pickBirthCertificate,
                          onUpload: _uploadBirthCertificate,
                        ),
                      ],
                    ),

                    // Additional Information
                    AdditionalInformationSection(
                      notesController: _notesController,
                    ),

                    const SizedBox(height: 20),

                    Consumer<ConfirmationProvider>(
                      builder: (context, confirmationProvider, _) {
                        return CustomButton(
                          width: double.infinity,
                          text: "Submit Booking",
                          onPressed: _submitForm,
                          isLoading: confirmationProvider.isLoading,
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
