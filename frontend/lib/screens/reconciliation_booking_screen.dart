import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/parish_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:diocese_frontend/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/reconciliation_provider.dart';
import '../utils/validators.dart';

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  // Controllers
  final TextEditingController _penitentNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _confessionType = 'Regular';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final parishProvider =
          Provider.of<ParishProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      parishProvider.clearSelection();

      // Default contact email to current user's email if available
      if (authProvider.currentUser?.email != null) {
        _contactEmailController.text = authProvider.currentUser!.email;
      }

      await parishProvider.loadParishesByService(
        'reconciliation',
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
        }
      }
    });
  }

  @override
  void dispose() {
    _penitentNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reconciliationProvider =
        Provider.of<ReconciliationProvider>(context, listen: false);
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
        const SnackBar(
            content:
                Text("Authentication token not found. Please login again.")),
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

    final success = await reconciliationProvider.createReconciliationBooking(
      token: token,
      parishId: parishProvider.selectedParish!.id!,
      penitentName: _penitentNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),

      //QA Fix: Add the trim method inside the format Date
      preferredDate: formatDate(_preferredDateController.text.trim()),
      preferredTimeSlot: _preferredTimeController.text.trim(),
      notes: notesToAdd,
    );

    if (success && mounted) {
      _formKey.currentState?.reset();
      Navigator.of(context).pop(true); // Go back
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(reconciliationProvider.errorMessage ??
                "Failed to submit booking.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sacrament of Reconciliation"),
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
                      "Fill out the form below to submit your reconciliation booking request. All fields marked with * are required.",
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

                    // Penitent Information
                    BookingSection(
                      title: "Penitent Information",
                      children: [
                        BookingTextField(
                          controller: _penitentNameController,
                          label: "Penitent Name *",
                          validator: Validators.requiredField,
                        ),
                      ],
                    ),

                    // Contact Information
                    ContactInformationSection(
                      emailController: _contactEmailController,
                      phoneController: _contactPhoneController,
                      emailValidator: Validators.emailValidator,
                      phoneValidator: Validators.phoneValidator,
                    ),

                    // Confession Request
                    BookingSection(
                      title: "Confession Request",
                      children: [
                        const Text(
                          "The Sacrament of Penance is the method by which individual men and women may confess sins committed after baptism and have them absolved by a priest.",
                        ),
                        const SizedBox(height: 16),
                        BookingDropdown<String>(
                          initialValue: _confessionType,
                          label: "Type of Confession",
                          items: const [
                            DropdownMenuItem(
                              value: "Regular",
                              child: Text("Regular"),
                            ),
                            DropdownMenuItem(
                              value: "First Confession",
                              child: Text("First Confession"),
                            ),
                            DropdownMenuItem(
                              value: "Spiritual Direction",
                              child: Text("Spiritual Direction"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _confessionType = value!);
                          },
                        ),
                      ],
                    ),

                    // Booking Preferences
                    BookingSection(
                      title: "Booking Preferences",
                      children: [
                        const ParishDropdown(),
                        BookingDateField(
                          controller: _preferredDateController,
                          label: "Preferred Reconciliation Date *",
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
                      ],
                    ),

// Schedule Note
                    const BookingSection(
                      title: "Schedule Note",
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                          ),
                          title: Text("Regular Confession Hours"),
                          subtitle: Text(
                            "Mon-Sat: 5:00 PM - 6:00 PM\nSundays: During all Masses",
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "For private confession appointments, the parish office will contact you after submission.",
                        ),
                      ],
                    ),

                    // Additional Information
                    AdditionalInformationSection(
                      notesController: _notesController,
                    ),

                    const SizedBox(height: 24),
                    Consumer<ReconciliationProvider>(
                      builder: (context, reconciliationProvider, _) {
                        return CustomButton(
                          width: double.infinity,
                          text: "Submit Booking",
                          onPressed: _submitForm,
                          isLoading: reconciliationProvider.isLoading,
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
