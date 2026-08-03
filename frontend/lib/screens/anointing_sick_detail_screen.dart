import 'package:diocese_frontend/extensions/build_context_extensions.dart';
import 'package:diocese_frontend/models/note.dart';
import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_detail_title.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/booking_status_actions_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/anointing_sick_booking.dart';
import '../providers/auth_provider.dart';
import '../providers/priest_provider.dart';
import '../services/anointing_sick_service.dart';
import '../widgets/notes_display.dart';

class AnointingSickDetailScreen extends StatefulWidget {
  final int? anointingSickId;
  final bool fromStatusButton;

  const AnointingSickDetailScreen({
    super.key,
    required this.anointingSickId,
    this.fromStatusButton = false,
  });

  @override
  State<AnointingSickDetailScreen> createState() =>
      _AnointingSickDetailScreenState();
}

class _AnointingSickDetailScreenState extends State<AnointingSickDetailScreen> {
  final AnointingSickService _anointingSickService = AnointingSickService();
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  bool _isEditMode = false;
  bool _isSaving = false;

  AnointingSickBooking? _booking;
  int? _selectedPriestId;

  final TextEditingController _sickPersonNameController =
      TextEditingController();
  final TextEditingController _contactPersonNameController =
      TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _locationAddressController =
      TextEditingController();
  final TextEditingController _preferredParishController =
      TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    if (widget.anointingSickId == null || widget.anointingSickId == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    final result = await _anointingSickService.getAnointingSickBookingById(
      token: token,
      id: widget.anointingSickId!,
    );

    if (mounted && result.success && result.data != null) {
      final booking = result.data!;
      final status = booking.status.toLowerCase();
      final isEditable = status == 'pending' || status == 'declined';
      setState(() {
        _booking = booking;
        _sickPersonNameController.text = booking.sickPersonName ?? '';
        _contactPersonNameController.text = booking.contactPersonName ?? '';
        _contactEmailController.text = booking.contactEmail ?? '';
        _contactPhoneController.text = booking.contactPhone ?? '';
        _locationController.text = booking.location ?? '';
        _locationAddressController.text = booking.locationAddress ?? '';
        _preferredParishController.text = booking.parishName ?? '';
        _preferredDateController.text =
            booking.preferredDate?.split('T')[0] ?? '';
        _preferredTimeController.text = booking.preferredTimeSlot ?? '';
        if (booking.priestId != null) {
          _selectedPriestId = booking.priestId;
        }
      });

      await context.read<PriestProvider>().loadPriestsByParish(
            booking.parishId,
            token: authProvider.token,
          );

      if (!mounted) return;

      // Auto-enable edit mode if user is owner and booking is editable
      final currentUser = authProvider.currentUser;
      final isOwner = booking.userId == currentUser?.id;
      if (isOwner && isEditable) {
        setState(() => _isEditMode = true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to load booking')));
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    if (!_validateForm()) return;

    if (widget.anointingSickId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required')));
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final note = Note.fromInput(
        text: _notesController.text,
        currentUser: context.read<AuthProvider>().currentUser,
      );

      final notesToAdd = note == null ? null : [note.toJson()];

      final result = await _anointingSickService.updateAnointingSickBooking(
        token: token,
        id: widget.anointingSickId!,
        sickPersonName: _sickPersonNameController.text.trim(),
        contactPersonName: _contactPersonNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim().isEmpty
            ? null
            : _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        location: _locationController.text.trim(),
        locationAddress: _locationAddressController.text.trim().isEmpty
            ? null
            : _locationAddressController.text.trim(),
        preferredDate: _preferredDateController.text,
        preferredTimeSlot: _preferredTimeController.text,
        priestId: _selectedPriestId,
        notes: notesToAdd,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking updated successfully')));
          _notesController.clear();
          _toggleEditMode();
          await _loadBooking();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message ?? 'Failed')));
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

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _updateStatus(String status) async {
    if (widget.anointingSickId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    context.handleBookingStatusUpdate(
      _anointingSickService.updateAnointingSickStatus(
        token: token,
        id: widget.anointingSickId!,
        status: status,
      ),
      status,
    );
  }

  Future<void> _resubmitBooking() async {
    if (widget.anointingSickId == null) return;

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

      final result = await _anointingSickService.resubmitBooking(
        id: widget.anointingSickId!,
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

    return Scaffold(
      appBar: AppBar(
        title: BookingDetailTitle(
            title: 'Anointing the Sick Details', status: status),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: Icon(_isSaving ? Icons.edit : Icons.save),
              tooltip: _isSaving ? 'Saving...' : 'Save changes',
              color: _isSaving ? Colors.orange : null,
              onPressed: _saveChanges,
            )
          else if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: _toggleEditMode,
            )
          else
            const SizedBox.shrink(),
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
                    BookingSection(
                      title: "Patient Information",
                      children: [
                        BookingTextField(
                          controller: _sickPersonNameController,
                          label: "Patient Full Name *",
                          validator: Validators.requiredField,
                          enabled: _isEditMode,
                        ),
                        BookingTextField(
                          controller: _locationController,
                          label: "Location (Hospital Name / Home Address) *",
                          maxLines: 2,
                          validator: Validators.requiredField,
                          enabled: _isEditMode,
                        ),
                        BookingTextField(
                          controller: _locationAddressController,
                          label: "Detailed Address (Optional)",
                          maxLines: 2,
                          enabled: _isEditMode,
                        ),
                      ],
                    ),
                    ContactInformationSection(
                      contactPersonController: _contactPersonNameController,
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
                          enabled: _isEditMode,
                          controller: _preferredDateController,
                          label: 'Preferred Anointing Date *',
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          validator: Validators.requiredField,
                        ),
                        BookingTimeField(
                          enabled: _isEditMode,
                          controller: _preferredTimeController,
                          label: 'Preferred Time Slot *',
                          validator: Validators.requiredField,
                        ),
                        PriestDropdown(
                          enabled: _isEditMode,
                          selectedPriestId: _selectedPriestId,
                          onChanged: (value) {
                            setState(() => _selectedPriestId = value);
                          },
                        ),
                      ],
                    ),
                    NotesDisplay(notes: _booking?.notes),
                    if (_isEditMode) ...[
                      AdditionalInformationSection(
                        notesController: _notesController,
                      ),
                    ],
                    if (status == 'declined' && isOwner) ...[
                      const SizedBox(height: 20),
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
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Resubmit Booking'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _resubmitBooking,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    BookingStatusActionsSection(
                      visible: isAdmin && !_isEditMode,
                      status: _booking?.status ?? 'pending',
                      onUpdateStatus: _updateStatus,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sickPersonNameController.dispose();
    _contactPersonNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _locationController.dispose();
    _locationAddressController.dispose();
    _preferredParishController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
