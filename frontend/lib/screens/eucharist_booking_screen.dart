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
import 'package:diocese_frontend/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/eucharist_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/priest_provider.dart';
import '../services/file_service.dart';
import '../utils/validators.dart';

class EucharistScreen extends StatefulWidget {
  const EucharistScreen({super.key});

  @override
  State<EucharistScreen> createState() => _EucharistScreenState();
}

class _EucharistScreenState extends State<EucharistScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  // Controllers
  final TextEditingController _communicantNameController =
      TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Priest selection state
  int? _selectedPriestId;

  // Document files and upload data
  PlatformFile? _birthCertificateFile;
  bool _isUploadingBirth = false;
  Map<String, dynamic>? _uploadedBirthData;

  PlatformFile? _baptismalCertificateFile;
  bool _isUploadingBaptismal = false;
  Map<String, dynamic>? _uploadedBaptismalData;

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
      _populateContactInfo(authProvider);

      await parishProvider.loadParishesByService(
        'eucharist',
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

  @override
  void dispose() {
    _communicantNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Birth Certificate
  Future<void> _pickBirthCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _birthCertificateFile = result.files.first;
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
    if (_birthCertificateFile == null) {
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

    setState(() => _isUploadingBirth = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _birthCertificateFile!,
        token: token,
        category: 'eucharist',
        additionalFields: {
          'documentType': 'birth_certificate',
        },
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _uploadedBirthData = response.data!['file'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Birth certificate uploaded successfully')),
          );
        } else {
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
        setState(() => _isUploadingBirth = false);
      }
    }
  }

  // Baptismal Certificate
  Future<void> _pickBaptismalCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _baptismalCertificateFile = result.files.first;
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
    if (_baptismalCertificateFile == null) {
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

    setState(() => _isUploadingBaptismal = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _baptismalCertificateFile!,
        token: token,
        category: 'eucharist',
        additionalFields: {
          'documentType': 'baptismal_certificate',
        },
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _uploadedBaptismalData = response.data!['file'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Baptismal certificate uploaded successfully')),
          );
        } else {
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
        setState(() => _isUploadingBaptismal = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eucharistProvider =
        Provider.of<EucharistProvider>(context, listen: false);
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

    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication token not available.")),
      );
      return;
    }

    // Validate required documents are uploaded
    if (_uploadedBirthData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please upload the required Birth Certificate.")),
      );
      return;
    }
    if (_uploadedBaptismalData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please upload the required Baptismal Certificate.")),
      );
      return;
    }

    // Build documents array
    final documents = [
      {
        'uploadedFile': _uploadedBirthData!['filename'],
        'filePath': _uploadedBirthData!['path'],
        'fileUrl': _uploadedBirthData!['url'],
        'fileSize': _uploadedBirthData!['size'],
        'mimeType': _uploadedBirthData!['mimeType'],
        'documentType': 'birth_certificate',
      },
      {
        'uploadedFile': _uploadedBaptismalData!['filename'],
        'filePath': _uploadedBaptismalData!['path'],
        'fileUrl': _uploadedBaptismalData!['url'],
        'fileSize': _uploadedBaptismalData!['size'],
        'mimeType': _uploadedBaptismalData!['mimeType'],
        'documentType': 'baptismal_certificate',
      },
    ];

    // Format dates to ISO format (YYYY-MM-DD)
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

    final success = await eucharistProvider.createEucharistBooking(
      token: token,
      parishId: parishProvider.selectedParish!.id!,
      communicantName: _communicantNameController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      motherName: _motherNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),

      //QA Fix: Added .trim() in this code for the preferred date
      preferredDate: formatDate(_preferredDateController.text.trim()),
      preferredTimeSlot: _preferredTimeController.text.trim(),
      priestId: _selectedPriestId,
      notes: notesToAdd,
      documents: documents,
    );

    if (success && mounted) {
      _formKey.currentState?.reset();
      Navigator.of(context).pop(true); // Go back
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                eucharistProvider.errorMessage ?? "Failed to submit booking.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parishProvider = context.watch<ParishProvider>();
    final hasSelectedParish = parishProvider.selectedParish != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("First Holy Communion"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Back to Home
          },
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
                      "Subject to availability. Parish will confirm your booking.",
                      style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Communicant Information Section
                    BookingSection(
                      title: "Communicant Information",
                      children: [
                        BookingTextField(
                          controller: _communicantNameController,
                          label: "Communicant Name *",
                          validator: Validators.requiredField,
                        ),
                      ],
                    ),

                    // Parents Information Section
                    ParentInformationSection(
                      fatherController: _fatherNameController,
                      motherController: _motherNameController,
                    ),

                    // Contact Information Section
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
                      title: "Booking Preferences",
                      children: [
                        ParishDropdown(
                          onParishChanged: () {
                            setState(() => _selectedPriestId = null);
                          },
                        ),
                        BookingDateField(
                          controller: _preferredDateController,
                          label: "Preferred Eucharist Date *",
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          validator: Validators.requiredField,
                        ),
                        BookingTimeField(
                          controller: _preferredTimeController,
                          label: "Preferred Time Slot *",
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
                    // Required Documents - Separate uploads
                    BookingSection(
                      title: "Required Documents",
                      children: [
                        DocumentUploadSection(
                          title: "Birth Certificate *",
                          description:
                              "Upload birth certificate of the communicant *",
                          file: _birthCertificateFile,
                          isUploading: _isUploadingBirth,
                          isUploaded: _uploadedBirthData != null,
                          onPick: _pickBirthCertificate,
                          onUpload: _uploadBirthCertificate,
                        ),
                        const SizedBox(height: 24),
                        DocumentUploadSection(
                          title: "Baptismal Certificate *",
                          description:
                              "Upload baptismal certificate of the communicant *",
                          file: _baptismalCertificateFile,
                          isUploading: _isUploadingBaptismal,
                          isUploaded: _uploadedBaptismalData != null,
                          onPick: _pickBaptismalCertificate,
                          onUpload: _uploadBaptismalCertificate,
                        ),
                      ],
                    ),

                    // Additional Information
                    AdditionalInformationSection(
                      notesController: _notesController,
                    ),

                    const SizedBox(height: 20),

                    Consumer<EucharistProvider>(
                      builder: (context, eucharistProvider, _) {
                        return CustomButton(
                          width: double.infinity,
                          text: "Submit Booking",
                          onPressed: _submitForm,
                          isLoading: eucharistProvider.isLoading,
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
