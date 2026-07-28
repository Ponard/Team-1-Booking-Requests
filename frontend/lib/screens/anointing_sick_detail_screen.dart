import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/priest_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
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
  bool _showStatusButtons = true;

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
    _showStatusButtons = !widget.fromStatusButton;
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

      if (widget.fromStatusButton && isEditable) {
        setState(() => _isEditMode = true);
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        final isOwner = booking.userId == currentUser?.id;
        if (!widget.fromStatusButton && isOwner && isEditable) {
          setState(() => _isEditMode = true);
        }
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
      List<Map<String, dynamic>>? notesToAdd;
      if (_notesController.text.trim().isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        notesToAdd = [
          {
            'author': 'parishioner',
            'content': _notesController.text.trim(),
            'authorId': authProvider.currentUser!.id,
          }
        ];
      }

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
          _toggleEditMode();
          Navigator.pop(context, true);
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
      if (!_isEditMode) _showStatusButtons = true;
    });
  }

  void _updateStatus(String status) async {
    if (widget.anointingSickId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    final result = await _anointingSickService.updateAnointingSickStatus(
      token: token,
      id: widget.anointingSickId!,
      status: status,
    );

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Booking marked as $status')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message ?? 'Failed')));
      }
    }
  }

  String get _displayStatus {
    if (_booking == null) return 'PENDING';
    final status = _booking!.status.toUpperCase();
    return status;
  }

  bool get _canChangeStatus {
    if (_booking == null) return false;
    final status = _booking!.status.toLowerCase();
    if (status == 'pending') {
      return true;
    } else if (status == 'approved') {
      final scheduledDate = _booking!.preferredDate;
      if (scheduledDate != null && scheduledDate.isNotEmpty) {
        try {
          final now = DateTime.now();
          final bookingDate = DateTime.parse(scheduledDate);
          final today = DateTime(now.year, now.month, now.day);
          final eventDate =
              DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          return eventDate.isBefore(today);
        } catch (e) {
          return false;
        }
      }
      return false;
    }
    return false;
  }

  String get _actionButtonText {
    if (_booking == null) return 'Approve';
    final status = _booking!.status.toLowerCase();
    if (status == 'pending') return 'Approve';
    if (status == 'approved') return 'Mark as Completed';
    return 'Approve';
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
        title: const Text("Anointing of the Sick Details"),
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
          else if (!_showStatusButtons && canEdit)
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
                          controller: _preferredDateController,
                          label: 'Preferred Anointing Date *',
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
                    _buildStatusSection(isAdmin, widget.anointingSickId ?? 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(bool isAdmin, int bookingId) {
    if (!isAdmin || _showStatusButtons) return const SizedBox.shrink();

    final displayStatus = _displayStatus;
    final canChangeStatus = _canChangeStatus;
    final actionButtonText = _actionButtonText;
    final status = _booking?.status.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Text(
                  displayStatus,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        if (status == 'pending') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => _updateStatus('approved'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Decline'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _updateStatus('declined'),
                ),
              ),
            ],
          ),
        ] else if (status == 'approved') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(actionButtonText),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed:
                      canChangeStatus ? () => _updateStatus('completed') : null,
                ),
              ),
            ],
          ),
        ],
      ],
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
