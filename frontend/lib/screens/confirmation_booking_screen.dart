import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/confirmation_provider.dart';
import '../providers/priest_provider.dart';
import '../services/file_service.dart';

class ConfirmationBookingScreen extends StatefulWidget {
  const ConfirmationBookingScreen({super.key});

  @override
  State<ConfirmationBookingScreen> createState() =>
      _ConfirmationBookingScreenState();
}

class _ConfirmationBookingScreenState extends State<ConfirmationBookingScreen> {
  // Global key for form validation
  final _formKey = GlobalKey<FormState>();

  // --- Controllers for text inputs ---
  final TextEditingController _confirmandNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _sponsorController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredDateController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // --- State Variables ---
  int? _selectedPriestId;

  // Baptismal Certificate upload state
  PlatformFile? _baptismalCertificate;
  bool _isUploadingBaptismal = false;
  Map<String, dynamic>? _uploadedBaptismalData;

  // Birth Certificate upload state
  PlatformFile? _birthCertificate;
  bool _isUploadingBirth = false;
  Map<String, dynamic>? _uploadedBirthData;

  @override
  void initState() {
    super.initState();
    // Load parishes and setup initial state after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final priestProvider = Provider.of<PriestProvider>(context, listen: false);

      await parishProvider.loadAllParishes();

      final userParishId = authProvider.currentUser?.preferredParishId;

      // Default to user's preferred parish if available
      if (userParishId != null) {
        final userParish = parishProvider.parishes
            .where((p) => p.id == userParishId)
            .firstOrNull;

        if (userParish != null) {
          parishProvider.selectParish(userParish);
          await priestProvider.loadPriestsByParish(userParishId);
        }
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers to free up memory
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

  // --- Document Handling: Baptismal Certificate ---
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
          _uploadedBaptismalData = null; // Reset upload data if new file picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
      }
    }
  }

  Future<void> _uploadBaptismalCertificate() async {
    if (_baptismalCertificate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file first')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to upload files')));
      return;
    }

    setState(() => _isUploadingBaptismal = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _baptismalCertificate!,
        token: token,
        category: 'confirmation',
        additionalFields: {'documentType': 'baptismal_certificate'},
      );

      if (response.success && response.data != null) {
        setState(() => _uploadedBaptismalData = response.data!['file']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baptismal certificate uploaded successfully')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message ?? 'Upload failed')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingBaptismal = false);
    }
  }

  // --- Document Handling: Birth Certificate ---
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
          _uploadedBirthData = null; // Reset upload data if new file picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
      }
    }
  }

  Future<void> _uploadBirthCertificate() async {
    if (_birthCertificate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file first')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to upload files')));
      return;
    }

    setState(() => _isUploadingBirth = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _birthCertificate!,
        token: token,
        category: 'confirmation',
        additionalFields: {'documentType': 'birth_certificate'},
      );

      if (response.success && response.data != null) {
        setState(() => _uploadedBirthData = response.data!['file']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Birth certificate uploaded successfully')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message ?? 'Upload failed')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingBirth = false);
    }
  }

  // --- Form Submission Logic ---
  Future<void> _submitForm() async {
    // 1. Initial form validation
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirmationProvider = Provider.of<ConfirmationProvider>(context, listen: false);
    final parishProvider = Provider.of<ParishProvider>(context, listen: false);

    // 2. State requirements validation
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to submit a booking.")));
      return;
    }
    if (parishProvider.selectedParish == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a parish.")));
      return;
    }
    if (_uploadedBaptismalData == null || _uploadedBirthData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload both required certificates.")));
      return;
    }

    // Helper for formatting date consistently to backend standards
    String formatDate(String date) {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
      }
      return date;
    }

    // --- Sanitization Block ---
    // Safely extracts and trims all inputs for pristine data hygiene
    final cleanConfirmand = _confirmandNameController.text.trim();
    final cleanFather = _fatherNameController.text.trim();
    final cleanMother = _motherNameController.text.trim();
    final cleanSponsor = _sponsorController.text.trim();
    final cleanEmail = _contactEmailController.text.trim().isNotEmpty
        ? _contactEmailController.text.trim()
        : authProvider.currentUser!.email;
    final cleanPhone = _contactPhoneController.text.trim();
    final cleanDate = formatDate(_preferredDateController.text.trim());
    final cleanTime = _preferredTimeController.text.trim();
    final cleanNotes = _notesController.text.trim();

    // Prepare notes dynamically if populated
    List<Map<String, dynamic>>? notesToAdd;
    if (cleanNotes.isNotEmpty) {
      notesToAdd = [{
        'author': 'parishioner',
        'content': cleanNotes,
        'authorId': authProvider.currentUser!.id,
      }];
    }

    // 3. Execute API Call
    final success = await confirmationProvider.createConfirmationBooking(
      token: authProvider.token!,
      parishId: parishProvider.selectedParish!.id!,
      confirmandName: cleanConfirmand,
      fatherName: cleanFather,
      motherName: cleanMother,
      sponsorName: cleanSponsor,
      contactEmail: cleanEmail,
      contactPhone: cleanPhone,
      preferredDate: cleanDate,
      preferredTimeSlot: cleanTime,
      priestId: _selectedPriestId,
      notes: notesToAdd,
      baptismalCertificate: _uploadedBaptismalData,
      birthCertificate: _uploadedBirthData,
    );

    // 4. Handle UI Response
    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Booking Submitted"),
          content: const Text("Your confirmation booking request has been submitted. Parish will confirm availability."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Pop back to home/dashboard
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(confirmationProvider.errorMessage ?? "Failed to submit booking.")),
      );
    }
  }

  // UI helper for structured layout
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmation Booking"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
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
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Confirmand Info Section
                  _buildSection(
                    title: "Confirmand Information",
                    children: [
                      TextFormField(
                        controller: _confirmandNameController,
                        decoration: const InputDecoration(labelText: "Confirmand Name *", border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fatherNameController,
                              decoration: const InputDecoration(labelText: "Father's Name *", border: OutlineInputBorder()),
                              validator: (value) => value == null || value.isEmpty ? "Required" : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _motherNameController,
                              decoration: const InputDecoration(labelText: "Mother's Name *", border: OutlineInputBorder()),
                              validator: (value) => value == null || value.isEmpty ? "Required" : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Sponsor Section
                  _buildSection(
                    title: "Sponsor / Godparent",
                    children: [
                      TextFormField(
                        controller: _sponsorController,
                        decoration: const InputDecoration(labelText: "Sponsor/Godparent Name *", border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      ),
                    ],
                  ),

                  // Contact Details Section
                  _buildSection(
                    title: "Contact Information",
                    children: [
                      TextFormField(
                        controller: _contactEmailController,
                        decoration: const InputDecoration(labelText: "Contact Email *", hintText: "email@example.com", border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactPhoneController,
                        decoration: const InputDecoration(labelText: "Contact Phone *", hintText: "+63 XXX XXX XXXX", border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      ),
                    ],
                  ),

                  // File Upload Section
                  _buildSection(
                    title: "Required Documents",
                    children: [
                      // Baptismal Certificate Block
                      const Text("Baptismal Certificate *", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text("Please upload a copy of the baptismal certificate. Accepted formats: PDF, JPG, PNG", style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickBaptismalCertificate,
                        icon: const Icon(Icons.attach_file),
                        label: Text(_baptismalCertificate != null ? 'File Selected: ${_baptismalCertificate!.name}' : 'Select Baptismal Certificate File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _baptismalCertificate != null ? Colors.green[100] : Colors.grey[200],
                          foregroundColor: Colors.black87,
                        ),
                      ),
                      if (_baptismalCertificate != null) ...[
                        const SizedBox(height: 12),
                        _isUploadingBaptismal
                            ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Uploading...'),
                          ],
                        )
                            : ElevatedButton.icon(
                          onPressed: _uploadedBaptismalData == null ? _uploadBaptismalCertificate : null,
                          icon: const Icon(Icons.cloud_upload),
                          label: Text(_uploadedBaptismalData != null ? 'Uploaded Successfully' : 'Upload Baptismal Certificate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _uploadedBaptismalData != null ? Colors.green : null,
                            foregroundColor: _uploadedBaptismalData != null ? Colors.white : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Birth Certificate Block
                      const Text("Birth Certificate *", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text("Please upload a copy of the birth certificate. Accepted formats: PDF, JPG, PNG", style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickBirthCertificate,
                        icon: const Icon(Icons.attach_file),
                        label: Text(_birthCertificate != null ? 'File Selected: ${_birthCertificate!.name}' : 'Select Birth Certificate File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _birthCertificate != null ? Colors.green[100] : Colors.grey[200],
                          foregroundColor: Colors.black87,
                        ),
                      ),
                      if (_birthCertificate != null) ...[
                        const SizedBox(height: 12),
                        _isUploadingBirth
                            ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Uploading...'),
                          ],
                        )
                            : ElevatedButton.icon(
                          onPressed: _uploadedBirthData == null ? _uploadBirthCertificate : null,
                          icon: const Icon(Icons.cloud_upload),
                          label: Text(_uploadedBirthData != null ? 'Uploaded Successfully' : 'Upload Birth Certificate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _uploadedBirthData != null ? Colors.green : null,
                            foregroundColor: _uploadedBirthData != null ? Colors.white : null,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Preferences & Scheduling Section
                  _buildSection(
                    title: "Booking Preferences",
                    children: [
                      Consumer<ParishProvider>(
                        builder: (context, parishProvider, _) {
                          return DropdownButtonFormField<int>(
                            value: parishProvider.selectedParish?.id,
                            decoration: const InputDecoration(labelText: "Preferred Parish *", border: OutlineInputBorder()),
                            items: parishProvider.parishes.map((parish) => DropdownMenuItem(value: parish.id, child: Text(parish.name))).toList(),
                            onChanged: (value) {
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final parish = parishProvider.parishes.firstWhere((p) => p.id == value);
                              setState(() => _selectedPriestId = null); // Clear old priest
                              parishProvider.selectParish(parish);
                              Provider.of<PriestProvider>(context, listen: false).loadPriestsByParish(parish.id!, token: authProvider.token);
                            },
                            validator: (value) => value == null ? "Please select a parish" : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _preferredDateController,
                        decoration: const InputDecoration(labelText: "Preferred Confirmation Date *", hintText: "YYYY-MM-DD", border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                        readOnly: true, // Prevent manual text entry for dates
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            _preferredDateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _preferredTimeController,
                        decoration: const InputDecoration(labelText: "Preferred Time Slot *", hintText: "HH:MM", border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                        readOnly: true, // Prevent manual text entry for time
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null && mounted) {
                            _preferredTimeController.text = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Consumer<PriestProvider>(
                        builder: (context, priestProvider, _) {
                          final validPriestId = _selectedPriestId != null && priestProvider.priests.any((p) => p.id == _selectedPriestId) ? _selectedPriestId : null;
                          return DropdownButtonFormField<int>(
                            value: validPriestId,
                            decoration: const InputDecoration(labelText: "Preferred Priest (Optional) - Subject to availability", border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem<int>(value: null, child: Text("No preference")),
                              ...priestProvider.priests.map((priest) => DropdownMenuItem<int>(value: priest.id, child: Text(priest.fullName))),
                            ],
                            onChanged: (value) => setState(() => _selectedPriestId = value),
                          );
                        },
                      ),
                    ],
                  ),

                  // Notes Section
                  _buildSection(
                    title: "Additional Information",
                    children: [
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: "Additional Notes", border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Submission Action
                  Consumer<ConfirmationProvider>(
                    builder: (context, confirmationProvider, _) {
                      return Center(
                        child: ElevatedButton(
                          onPressed: confirmationProvider.isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: confirmationProvider.isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                              : const Text("Submit Booking", style: TextStyle(fontSize: 16)),
                        ),
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
    );
  }
}