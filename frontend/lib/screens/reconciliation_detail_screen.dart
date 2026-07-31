import 'package:diocese_frontend/extensions/build_context_extensions.dart';
import 'package:diocese_frontend/models/note.dart';
import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_detail_title.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_time_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/booking_status_actions_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/contact_information_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/reconciliation_service.dart';
import '../models/reconciliation_booking.dart';
import '../widgets/notes_display.dart';

class ReconciliationDetailScreen extends StatefulWidget {
  final int? reconciliationId;
  final bool fromStatusButton;

  const ReconciliationDetailScreen({
    super.key,
    required this.reconciliationId,
    this.fromStatusButton = false,
  });

  @override
  State<ReconciliationDetailScreen> createState() =>
      _ReconciliationDetailScreenState();
}

class _ReconciliationDetailScreenState
    extends State<ReconciliationDetailScreen> {
  final ReconciliationService _reconciliationService = ReconciliationService();
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  bool _isEditMode = false;
  bool _isSaving = false;

  ReconciliationBooking? _booking;

  final TextEditingController _penitentNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredParishController =
      TextEditingController();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _confessionType = 'Regular';

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    if (widget.reconciliationId == null || widget.reconciliationId == 0) {
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

    final result = await _reconciliationService.getReconciliationById(
      token: token,
      id: widget.reconciliationId!,
    );

    if (mounted && result.success && result.data != null) {
      final booking = result.data!;
      setState(() {
        _booking = booking;
        _penitentNameController.text = booking.penitentName ?? '';
        _contactEmailController.text = booking.contactEmail ?? '';
        _contactPhoneController.text = booking.contactPhone ?? '';
        _preferredParishController.text = booking.parishName ?? '';
        _preferredDateController.text =
            booking.preferredDate?.split('T')[0] ?? '';
        _preferredTimeController.text = booking.preferredTimeSlot ?? '';
      });

      // Auto-enable edit mode if user is owner and booking is editable
      final currentUser = authProvider.currentUser;
      final isOwner = booking.userId == currentUser?.id;
      final status = booking.status.toLowerCase();
      final isEditable = status == 'pending' || status == 'declined';
      if (isOwner && isEditable) {
        setState(() => _isEditMode = true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to load booking')));
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return;
    }

    if (widget.reconciliationId == null) {
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

    setState(() => _isSaving = true);

    //QA FIX: Dynamic role check for notes
    final note = Note.fromInput(
      text: _notesController.text,
      currentUser: context.read<AuthProvider>().currentUser,
    );

    final notesToAdd = note == null ? null : [note.toJson()];

    //QA FIX: Added .trim() to date and time fields
    final result = await _reconciliationService.updateReconciliationBooking(
      token: token,
      id: widget.reconciliationId!,
      penitentName: _penitentNameController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      preferredDate: _preferredDateController.text.trim(),
      preferredTimeSlot: _preferredTimeController.text.trim(),
      notes: notesToAdd,
    );

    //QA FIX: Mounted check to prevent crash if user navigates away
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking updated successfully')));
        _notesController.clear();
        _toggleEditMode();
        await _loadBooking();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.message ?? 'Failed to update booking')));
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    if (widget.reconciliationId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    context.handleBookingStatusUpdate(
      _reconciliationService.updateReconciliationStatus(
        token: token,
        id: widget.reconciliationId!,
        status: status,
      ),
      status,
    );
  }

  Future<void> _resubmitBooking() async {
    if (widget.reconciliationId == null) return;

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

      final result = await _reconciliationService.resubmitBooking(
        id: widget.reconciliationId!,
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
        title:
            BookingDetailTitle(title: 'Reconciliation Details', status: status),
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
                      title: "Penitent Information",
                      children: [
                        BookingTextField(
                          controller: _penitentNameController,
                          label: "Penitent Name *",
                          validator: Validators.requiredField,
                          enabled: _isEditMode,
                        ),
                      ],
                    ),
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
                      enabled: _isEditMode,
                    ),
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
                          enabled: _isEditMode,
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
                          label: 'Preferred Reconciliation Date *',
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
                      ],
                    ),
                    NotesDisplay(notes: _booking?.notes),
                    if (_isEditMode) ...[
                      AdditionalInformationSection(
                        notesController: _notesController,
                      ),
                    ],
                    if (status == 'declined' && isOwner) ...[
                      const SizedBox(height: 16),
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
                    ],
                    BookingStatusActionsSection(
                      visible: isAdmin && !_isEditMode,
                      status: _booking?.status ?? 'pending',
                      onUpdateStatus: _updateStatus,
                    )
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
    _penitentNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredParishController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
