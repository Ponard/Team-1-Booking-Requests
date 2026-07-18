import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/parish_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/funeral_mass_provider.dart';
import '../providers/priest_provider.dart';
import '../widgets/custom_button.dart';
import '../utils/validators.dart';

class FuneralMassScreen extends StatefulWidget {
  static const routeName = '/funeral-mass';

  const FuneralMassScreen({super.key});

  @override
  State<FuneralMassScreen> createState() => _FuneralMassScreenState();
}

class _FuneralMassScreenState extends State<FuneralMassScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _deceasedNameController = TextEditingController();
  final _dateOfDeathController = TextEditingController();
  final _wakeStartDateController = TextEditingController();
  final _wakeEndDateController = TextEditingController();
  final _wakeLocationController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
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
        _emailController.text = authProvider.currentUser!.email;
      }
      if (authProvider.currentUser?.fullName != null) {
        _contactPersonController.text = authProvider.currentUser!.fullName;
      }

      await parishProvider.loadParishesByService(
        'funeral_mass',
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
    _deceasedNameController.dispose();
    _dateOfDeathController.dispose();
    _wakeStartDateController.dispose();
    _wakeEndDateController.dispose();
    _wakeLocationController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final funeralMassProvider =
          Provider.of<FuneralMassProvider>(context, listen: false);
      final parishProvider =
          Provider.of<ParishProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please login to submit a booking.")),
          );
        }
        return;
      }

      if (parishProvider.selectedParish == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a parish.")),
          );
        }
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

      final success = await funeralMassProvider.createFuneralMassBooking(
        token: authProvider.token!,
        parishId: parishProvider.selectedParish!.id!,
        deceasedFullName: _deceasedNameController.text.trim(),
        representativeName: _contactPersonController.text.trim(),
        contactEmail: _emailController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        preferredDate: formatDate(_preferredDateController.text),
        preferredTimeSlot: _preferredTimeController.text,
        dateOfDeath: _dateOfDeathController.text.trim().isEmpty
            ? null
            : formatDate(_dateOfDeathController.text),
        wakeStartDate: _wakeStartDateController.text.trim().isEmpty
            ? null
            : formatDate(_wakeStartDateController.text),
        wakeEndDate: _wakeEndDateController.text.trim().isEmpty
            ? null
            : formatDate(_wakeEndDateController.text),
        wakeLocation: _wakeLocationController.text.trim().isEmpty
            ? null
            : _wakeLocationController.text.trim(),
        priestId: _selectedPriestId,
        notes: notesToAdd,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Booking Submitted"),
            content: const Text(
                "Your funeral mass booking request has been submitted. The parish will contact you to confirm details."),
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
              content: Text(funeralMassProvider.errorMessage ??
                  "Failed to submit booking.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Funeral Mass Booking"),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Fill out the form below to submit your funeral mass booking request. All fields marked with * are required.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "The Parish office will contact you immediately to coordinate the priest's schedule for the mass and interment.",
                    style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Deceased Information
                  BookingSection(
                    title: "Deceased Information",
                    children: [
                      BookingTextField(
                        controller: _deceasedNameController,
                        label: "Full Name of the Deceased *",
                        validator: Validators.requiredField,
                      ),
                      BookingDateField(
                        controller: _dateOfDeathController,
                        label: "Date of Death (Optional)",
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      ),
                    ],
                  ),

                  // Wake Information
                  BookingSection(
                    title: "Wake Information",
                    children: [
                      BookingDateField(
                        controller: _wakeStartDateController,
                        label: "Wake Start Date (Optional)",
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      ),
                      BookingDateField(
                        controller: _wakeEndDateController,
                        label: "Wake End Date (Optional)",
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      ),
                      BookingTextField(
                        controller: _wakeLocationController,
                        label: "Wake Location/Chapel (Optional)",
                        maxLines: 2,
                      ),
                    ],
                  ),

                  // Contact Information
                  ContactInformationSection(
                    contactPersonController: _contactPersonController,
                    contactPersonLabel: "Family Representative Name *",
                    emailController: _emailController,
                    phoneController: _phoneController,
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
                        label: "Preferred Funeral Mass Date *",
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
                        onChanged: (value) {
                          setState(() => _selectedPriestId = value);
                        },
                      ),
                    ],
                  ),

                  // Additional Information
                  AdditionalInformationSection(
                    notesController: _additionalNotesController,
                  ),

                  const SizedBox(height: 24),

                  // Submit Button with loading state
                  Consumer<FuneralMassProvider>(
                    builder: (context, funeralMassProvider, _) {
                      return CustomButton(
                        width: double.infinity,
                        text: "Submit Booking",
                        onPressed: _submitForm,
                        isLoading: funeralMassProvider.isLoading,
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
