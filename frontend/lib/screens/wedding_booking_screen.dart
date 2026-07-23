import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/parish_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/couple_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/document_upload_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/sponsors_information_section.dart';
import 'package:diocese_frontend/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/wedding_provider.dart';
import '../providers/priest_provider.dart';
import '../services/file_service.dart';

class WeddingBookingScreen extends StatefulWidget {
  const WeddingBookingScreen({super.key});

  @override
  State<WeddingBookingScreen> createState() => _WeddingBookingScreenState();
}

class _WeddingBookingScreenState extends State<WeddingBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  // Controllers
  final TextEditingController _groomNameController = TextEditingController();
  final TextEditingController _brideNameController = TextEditingController();
  final TextEditingController _godparentsController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();
  final TextEditingController _seminarScheduleController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Priest selection state
  int? _selectedPriestId;

  // Document files and upload data
  PlatformFile? _cenomarFile;
  bool _isUploadingCenomar = false;
  Map<String, dynamic>? _uploadedCenomarData;

  PlatformFile? _birthCertificateFile;
  bool _isUploadingBirth = false;
  Map<String, dynamic>? _uploadedBirthData;

  PlatformFile? _baptismalCertificateFile;
  bool _isUploadingBaptismal = false;
  Map<String, dynamic>? _uploadedBaptismalData;

  PlatformFile? _confirmationCertificateFile;
  bool _isUploadingConfirmation = false;
  Map<String, dynamic>? _uploadedConfirmationData;

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

      // Set default contact to current user's email
      if (authProvider.currentUser?.email != null) {
        _contactEmailController.text = authProvider.currentUser!.email;
      }

      await parishProvider.loadParishesByService(
        'wedding',
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
    _groomNameController.dispose();
    _brideNameController.dispose();
    _godparentsController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _seminarScheduleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // CENOMAR
  Future<void> _pickCenomar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _cenomarFile = result.files.first;
          _uploadedCenomarData = null;
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

  Future<void> _uploadCenomar() async {
    if (_cenomarFile == null) {
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

    setState(() => _isUploadingCenomar = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _cenomarFile!,
        token: token,
        category: 'wedding',
        additionalFields: {
          'documentType': 'cenomar',
        },
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _uploadedCenomarData = response.data!['file'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CENOMAR uploaded successfully')),
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
        setState(() => _isUploadingCenomar = false);
      }
    }
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
        category: 'wedding',
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
        category: 'wedding',
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

  // Confirmation Certificate
  Future<void> _pickConfirmationCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _confirmationCertificateFile = result.files.first;
          _uploadedConfirmationData = null;
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

  Future<void> _uploadConfirmationCertificate() async {
    if (_confirmationCertificateFile == null) {
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

    setState(() => _isUploadingConfirmation = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _confirmationCertificateFile!,
        token: token,
        category: 'wedding',
        additionalFields: {
          'documentType': 'confirmation_certificate',
        },
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _uploadedConfirmationData = response.data!['file'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Confirmation certificate uploaded successfully')),
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
        setState(() => _isUploadingConfirmation = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final weddingProvider =
        Provider.of<WeddingProvider>(context, listen: false);
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

    // Validate all required documents are uploaded
    if (_uploadedCenomarData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload the required CENOMAR.")),
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
    if (_uploadedBaptismalData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please upload the required Baptismal Certificate.")),
      );
      return;
    }
    if (_uploadedConfirmationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please upload the required Confirmation Certificate.")),
      );
      return;
    }

    // Build documents array
    final documents = [
      {
        'uploadedFile': _uploadedCenomarData!['filename'],
        'filePath': _uploadedCenomarData!['path'],
        'fileUrl': _uploadedCenomarData!['url'],
        'fileSize': _uploadedCenomarData!['size'],
        'mimeType': _uploadedCenomarData!['mimeType'],
        'documentType': 'cenomar',
      },
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
      {
        'uploadedFile': _uploadedConfirmationData!['filename'],
        'filePath': _uploadedConfirmationData!['path'],
        'fileUrl': _uploadedConfirmationData!['url'],
        'fileSize': _uploadedConfirmationData!['size'],
        'mimeType': _uploadedConfirmationData!['mimeType'],
        'documentType': 'confirmation_certificate',
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

    // Format time to HH:MM
    String formatTime(String time) {
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
      }
      return time;
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

    // QA FIX: Input Sanitization
    // Added .trim() to text, date, and time controllers to strip trailing/leading whitespace,
    // preventing backend formatting errors and database corruption during submission.
    final success = await weddingProvider.createWeddingBooking(
      token: authProvider.token!,
      parishId: parishProvider.selectedParish!.id!,
      groomFullName: _groomNameController.text.trim(),
      brideFullName: _brideNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      preferredDate: formatDate(_preferredDateController.text.trim()),
      preferredTimeSlot: formatTime(_preferredTimeController.text.trim()),
      seminarSchedule: _seminarScheduleController.text.trim().isEmpty
          ? null
          : _seminarScheduleController.text.trim(),
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
                weddingProvider.errorMessage ?? "Failed to submit booking.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parishProvider = context.watch<ParishProvider>();
    final hasSelectedParish = parishProvider.selectedParish != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wedding Booking"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
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
                      "Subject to availability. Parish will confirm your booking and selected priest.",
                      style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Couple Info
                    CoupleInformationSection(
                      groomController: _groomNameController,
                      brideController: _brideNameController,
                    ),

                    // Sponsors
                    SponsorsInformationSection(
                      sponsorsController: _godparentsController,
                    ),

                    // Contact
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
                          label: 'Preferred Wedding Date *',
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
                        BookingDateField(
                          controller: _seminarScheduleController,
                          label: 'Seminar Schedule *',
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 730)),
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
                          title: "CENOMAR *",
                          description:
                              "Upload CENOMAR (Certificate of No Marriage) *",
                          file: _cenomarFile,
                          isUploading: _isUploadingCenomar,
                          isUploaded: _uploadedCenomarData != null,
                          onPick: _pickCenomar,
                          onUpload: _uploadCenomar,
                        ),
                        const SizedBox(height: 24),
                        DocumentUploadSection(
                          title: "Birth Certificate *",
                          description:
                              "Upload birth certificate of either the groom or bride *",
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
                              "Upload baptismal certificate of either the groom or bride *",
                          file: _baptismalCertificateFile,
                          isUploading: _isUploadingBaptismal,
                          isUploaded: _uploadedBaptismalData != null,
                          onPick: _pickBaptismalCertificate,
                          onUpload: _uploadBaptismalCertificate,
                        ),
                        const SizedBox(height: 24),
                        DocumentUploadSection(
                          title: "Confirmation Certificate *",
                          description:
                              "Upload confirmation certificate of either the groom or bride *",
                          file: _confirmationCertificateFile,
                          isUploading: _isUploadingConfirmation,
                          isUploaded: _uploadedConfirmationData != null,
                          onPick: _pickConfirmationCertificate,
                          onUpload: _uploadConfirmationCertificate,
                        ),
                      ],
                    ),

                    // Notes
                    AdditionalInformationSection(
                      notesController: _notesController,
                    ),

                    const SizedBox(height: 20),
                    Consumer<WeddingProvider>(
                      builder: (context, weddingProvider, _) {
                        return CustomButton(
                          width: double.infinity,
                          text: "Submit Booking",
                          onPressed: _submitForm,
                          isLoading: weddingProvider.isLoading,
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
