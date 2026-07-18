import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/parish_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:diocese_frontend/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/anointing_sick_provider.dart';
import '../providers/priest_provider.dart';
import '../utils/validators.dart';

class AnointingTheSickScreen extends StatefulWidget {
  static const routeName = '/anointing-the-sick';

  const AnointingTheSickScreen({super.key});

  @override
  State<AnointingTheSickScreen> createState() => _AnointingTheSickScreenState();
}

class _AnointingTheSickScreenState extends State<AnointingTheSickScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for required fields
  final _sickPersonNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _locationController = TextEditingController();

  // Controllers for optional fields
  final _locationAddressController = TextEditingController();
  final _preferredDateController = TextEditingController();
  final _preferredTimeController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  // Priest selection state
  int? _selectedPriestId;

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

      // Set default contact email and person to current user's info
      if (authProvider.currentUser?.email != null) {
        _contactEmailController.text = authProvider.currentUser!.email;
      }
      if (authProvider.currentUser?.fullName != null) {
        _contactPersonController.text = authProvider.currentUser!.fullName;
      }

      await parishProvider.loadParishesByService(
        'anointing_sick',
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
    _sickPersonNameController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _locationController.dispose();
    _locationAddressController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmission() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final anointingSickProvider =
          Provider.of<AnointingSickProvider>(context, listen: false);
      final parishProvider =
          Provider.of<ParishProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to submit a booking.")),
        );
        return;
      }

      if (parishProvider.selectedParish == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a parish.")),
        );
        return;
      }

      final token = authProvider.token;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication token not available.")),
        );
        return;
      }

      // Format dates to ISO format (YYYY-MM-DD)
      String formatDate(String date) {
        final parts = date.split('-');
        if (parts.length == 3) {
          return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
        }
        return date;
      }

      // Prepare notes array if additional notes were provided
      List<Map<String, dynamic>>? notesToAdd;
      if (_additionalNotesController.text.trim().isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        notesToAdd = [
          {
            'author': 'parishioner',
            'content': _additionalNotesController.text.trim(),
            'authorId': currentUser?.id,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ];
      }

      final success = await anointingSickProvider.createAnointingSickBooking(
        token: token,
        parishId: parishProvider.selectedParish!.id!,
        sickPersonName: _sickPersonNameController.text.trim(),
        contactPersonName: _contactPersonController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        location: _locationController.text.trim(),
        locationAddress: _locationAddressController.text.trim().isEmpty
            ? null
            : _locationAddressController.text.trim(),

        //QA FIX: Added trim method inside formatDate
        preferredDate: _preferredDateController.text.isEmpty
            ? null
            : formatDate(_preferredDateController.text.trim()),
        preferredTimeSlot: _preferredTimeController.text.trim().isEmpty
            ? null
            : _preferredTimeController.text.trim(),
        priestId: _selectedPriestId,
        notes: notesToAdd,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Booking Submitted"),
            content: const Text(
                "Your Anointing of the Sick booking request has been submitted. The parish will contact you to confirm arrangements."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Go back
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(anointingSickProvider.errorMessage ??
                  "Failed to submit booking.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anointing of the Sick"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                    "Subject to availability. Parish will confirm your booking arrangements.",
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Urgent Notice
                  Card(
                    color: Colors.red[50],
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.priority_high, color: Colors.red),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "For urgent cases requiring immediate attention, please call the Parish office directly.",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Patient Information
                  BookingSection(
                    title: "Patient Information",
                    children: [
                      BookingTextField(
                        controller: _sickPersonNameController,
                        label: "Patient Full Name *",
                        validator: Validators.requiredField,
                      ),
                      BookingTextField(
                        controller: _locationController,
                        label: "Location (Hospital Name / Home Address) *",
                        maxLines: 2,
                        validator: Validators.requiredField,
                      ),
                      BookingTextField(
                        controller: _locationAddressController,
                        label: "Detailed Address (Optional)",
                        maxLines: 2,
                      ),
                    ],
                  ),

                  // Contact Information
                  ContactInformationSection(
                    contactPersonController: _contactPersonController,
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
                        label: "Preferred Anointing Date (Optional)",
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      ),
                      BookingTimeField(
                        controller: _preferredTimeController,
                        label: "Preferred Time Slot (Optional)",
                      ),
                      PriestDropdown(
                        selectedPriestId: _selectedPriestId,
                        onChanged: (value) {
                          setState(() => _selectedPriestId = value);
                        },
                      ),
                    ],
                  ),

                  // Additional Notes
                  AdditionalInformationSection(
                    notesController: _additionalNotesController,
                    label:
                        "Additional Notes\n(Patient Condition, Special Requests)",
                  ),
                  const SizedBox(height: 20),

                  // Submit Button with loading state
                  Consumer<AnointingSickProvider>(
                    builder: (context, anointingSickProvider, _) {
                      return CustomButton(
                        width: double.infinity,
                        text: "Submit Booking",
                        onPressed: _handleSubmission,
                        isLoading: anointingSickProvider.isLoading,
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
