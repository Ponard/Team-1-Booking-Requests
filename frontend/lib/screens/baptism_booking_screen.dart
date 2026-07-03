import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/baptism_provider.dart';
import '../providers/priest_provider.dart';
import '../services/file_service.dart';

class BaptismBookingScreen extends StatefulWidget {
  const BaptismBookingScreen({super.key});

  @override
  State<BaptismBookingScreen> createState() => _BaptismBookingScreenState();
}

class _BaptismBookingScreenState extends State<BaptismBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _godparentsController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _preferredDateController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();

  // Priest selection state
  int? _selectedPriestId;

  // File upload state
  PlatformFile? _birthCertificateFile;
  bool _isUploadingFile = false;
  Map<String, dynamic>? _uploadedFileData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final priestProvider = Provider.of<PriestProvider>(context, listen: false);

      await parishProvider.loadAllParishes();

      final userParishId = authProvider.currentUser?.preferredParishId;

      if (userParishId != null) {
        final userParish = parishProvider.parishes.where((p) => p.id == userParishId).firstOrNull;
        if (userParish != null) {
          parishProvider.selectParish(userParish);
          await priestProvider.loadPriestsByParish(userParishId, token: authProvider.token);
        }
      }
    });
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _dobController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _godparentsController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    super.dispose();
  }

  // --- Upload Handlers ---
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
    }
  }

  Future<void> _uploadBirthCertificate() async {
    if (_birthCertificateFile == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isUploadingFile = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _birthCertificateFile!,
        token: token,
        category: 'baptism',
        additionalFields: {'documentType': 'birth_certificate'},
      );

      if (response.success && response.data != null) {
        setState(() => _uploadedFileData = response.data!['file']);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Birth certificate uploaded successfully')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message ?? 'Upload failed')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  // --- Submission Logic ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final baptismProvider = Provider.of<BaptismProvider>(context, listen: false);
    final parishProvider = Provider.of<ParishProvider>(context, listen: false);

    if (authProvider.currentUser == null || parishProvider.selectedParish == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Missing user or parish selection.")));
      return;
    }

    // Helper for formatting date consistently
    String formatDate(String date) {
      final parts = date.split('-');
      return parts.length == 3 ? '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}' : date;
    }

    // Parse godparents safely
    List<Map<String, String>> godparents = [];
    if (_godparentsController.text.trim().isNotEmpty) {
      final godparentsList = _godparentsController.text.split(';');
      for (var godparent in godparentsList) {
        if (godparent.trim().isNotEmpty) {
          godparents.add({'fullName': godparent.trim()});
        }
      }
    }

    // Sanitized payload construction
    final success = await baptismProvider.createBaptismBooking(
      parishId: parishProvider.selectedParish!.id!,
      childFullName: _childNameController.text.trim(),
      dateOfBirth: formatDate(_dobController.text.trim()),
      fatherName: _fatherNameController.text.trim(),
      motherName: _motherNameController.text.trim(),
      contactEmail: authProvider.currentUser!.email,
      contactPhone: _contactController.text.trim(),
      preferredDate: formatDate(_preferredDateController.text.trim()),
      preferredTimeSlot: _preferredTimeController.text.trim(),
      priestId: _selectedPriestId,
      notes: _notesController.text.trim().isNotEmpty
          ? [{'author': 'parishioner', 'content': _notesController.text.trim(), 'authorId': authProvider.currentUser!.id}]
          : null,
      godparents: godparents.isEmpty ? null : godparents,
      uploadedFile: _uploadedFileData?['filename'],
      filePath: _uploadedFileData?['path'],
      fileUrl: _uploadedFileData?['url'],
      fileSize: _uploadedFileData?['size'],
      mimeType: _uploadedFileData?['mimeType'],
      documentType: 'birth_certificate',
    );

    if (success && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Booking Submitted"),
          content: const Text("Your baptism booking request has been submitted."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(baptismProvider.errorMessage ?? "Failed to submit booking.")),
      );
    }
  }

  // --- UI Components ---
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
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
      appBar: AppBar(title: const Text("Baptism Booking"), centerTitle: true),
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
                  _buildSection(title: "Child Information", children: [
                    TextFormField(
                      controller: _childNameController,
                      decoration: const InputDecoration(labelText: "Child's Full Name *", border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(labelText: "Date of Birth *", hintText: "YYYY-MM-DD", border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                        if (pickedDate != null) _dobController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      },
                    ),
                  ]),
                  // ... rest of your UI widgets remain the same
                  const SizedBox(height: 20),
                  Consumer<BaptismProvider>(
                    builder: (context, baptismProvider, _) => ElevatedButton(
                      onPressed: baptismProvider.isLoading ? null : _submitForm,
                      child: baptismProvider.isLoading ? const CircularProgressIndicator() : const Text("Submit Request"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}