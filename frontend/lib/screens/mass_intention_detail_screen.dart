import 'package:diocese_frontend/extensions/build_context_extensions.dart';
import 'package:diocese_frontend/models/note.dart';
import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_detail_title.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/booking_status_actions_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mass_intention.dart';
import '../models/mass_schedule.dart';
import '../providers/auth_provider.dart';
import '../providers/mass_schedule_provider.dart';
import '../services/mass_intention_service.dart';
import '../widgets/notes_display.dart';

class MassIntentionDetailScreen extends StatefulWidget {
  final int? massIntentionId;
  final bool fromStatusButton;

  const MassIntentionDetailScreen({
    super.key,
    required this.massIntentionId,
    this.fromStatusButton = false,
  });

  @override
  State<MassIntentionDetailScreen> createState() =>
      _MassIntentionDetailScreenState();
}

class _MassIntentionDetailScreenState extends State<MassIntentionDetailScreen> {
  final MassIntentionService _massIntentionService = MassIntentionService();
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  bool _isLoadingIntention = false;
  bool _isEditMode = false;
  bool _isSaving = false;

  MassIntention? _intention;

  final TextEditingController _intentionForController = TextEditingController();
  final TextEditingController _offeredByController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _newNoteController = TextEditingController();
  final TextEditingController _parishNameController = TextEditingController();

  String? _selectedType;
  String? _selectedTime;
  DateTime? _selectedDate;
  List<MassSchedule> _availableSchedules = [];
  String _noSchedulesMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMassIntention();
  }

  Future<void> _loadMassIntention() async {
    if (widget.massIntentionId == null || widget.massIntentionId == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid ID')));
      return;
    }

    _isLoadingIntention = true;

    // print('=== Loading mass intention ID: ${widget.massIntentionId} ===');
    final result = await _massIntentionService.getMassIntentionById(
        id: widget.massIntentionId!);
    // print('Result success: ${result.success}');
    // print('Result data: ${result.data}');
    // print('Result message: ${result.message}');
    // print('Result errors: ${result.errors}');

    if (mounted && result.success && result.data != null) {
      final intention = result.data!;
      final status = intention.status?.toLowerCase() ?? 'pending';
      final isEditable = status == 'pending' || status == 'declined';

      String mapTypeToFrontend(String? backendType) {
        switch (backendType) {
          case 'Thanksgiving':
            return 'Thanksgiving';
          case 'Special Intention':
            return 'Special Intention';
          case 'For the Dead':
            return 'Soul / Death Anniversary';
          default:
            return 'Special Intention';
        }
      }

      setState(() {
        _intention = intention;
        _intentionForController.text = intention.intentionDetails ?? '';
        _offeredByController.text = intention.donorName ?? '';
        _parishNameController.text = intention.parishName ?? '';
        _selectedType = mapTypeToFrontend(intention.type);

        final massSchedule = intention.massSchedule ?? '';
        // print('[MassIntentionDetail] massSchedule: "$massSchedule"');
        if (massSchedule.isNotEmpty && massSchedule.contains('T')) {
          final utcDate = DateTime.parse(massSchedule);
          final phDate = utcDate.add(const Duration(hours: 8));
          _dateController.text =
              '${phDate.year}-${phDate.month.toString().padLeft(2, '0')}-${phDate.day.toString().padLeft(2, '0')}';
          _selectedTime = _normalizeTime(intention.preferredTimeSlot);
          // print(
          //     '[MassIntentionDetail] Parsed date (PH): "${_dateController.text}", time: "$_selectedTime"');
        } else {
          _dateController.text = intention.preferredDate ?? '';
          _selectedTime = _normalizeTime(intention.preferredTimeSlot);
          _selectedDate = DateTime.parse(_dateController.text);
          // print(
          //     '[MassIntentionDetail] Fallback date: "${_dateController.text}", time: "$_selectedTime"');
        }
        // Do not populate _newNoteController - it's for adding new notes
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_selectedDate != null) {
        await _loadSchedulesForDate(_selectedDate!);
      }

      final currentUser = authProvider.currentUser;
      final isOwner = intention.userId == currentUser?.id;
      if (isOwner && isEditable) {
        setState(() => _isEditMode = true);
      }
    } else if (mounted) {
      // print('Failed to load: ${result.message}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message ?? 'Failed to load mass intention')));
    }

    _isLoadingIntention = false;
  }

  String _normalizeTime(String? time) {
    if (time == null || time.isEmpty) return '';
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return time;
  }

  Future<void> _loadSchedulesForDate(DateTime date) async {
    final scheduleProvider =
        Provider.of<MassScheduleProvider>(context, listen: false);
    int? parishId = _intention?.parishId;

    // print(
    //     '[MassIntentionDetail] Loading schedules for parishId: $parishId, date: $date (${_getDayName(date.weekday)})');
    // print('[MassIntentionDetail] _intention.parishId: ${_intention?.parishId}');

    await scheduleProvider.loadSchedules(parishId: parishId);

    // print(
    //     '[MassIntentionDetail] All loaded schedules: ${scheduleProvider.schedules.length}');
    // for (final s in scheduleProvider.schedules) {
    //   print(
    //       '  - ${s.dayOfWeek} ${s.startTime} active: ${s.isActive} parishId: ${s.parishId}');
    // }

    List<MassSchedule> schedules = scheduleProvider.getSchedulesForDate(date);
    // print(
    //     '[MassIntentionDetail] Filtered schedules for ${_getDayName(date.weekday)}: ${schedules.length}');

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      final currentTimeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      schedules = schedules.where((s) {
        if (s.intentionCutoffTime == null) return true;
        return currentTimeStr.compareTo(s.intentionCutoffTime!) < 0;
      }).toList();
    }

    final normalizedSelectedTime = _normalizeTime(_selectedTime);

    setState(() {
      final allSchedules = scheduleProvider.getSchedulesForDate(date);
      if (_isLoadingIntention) {
        _availableSchedules = allSchedules;
        return;
      }
      _availableSchedules = schedules;
      _selectedTime = null;
      if (schedules.isNotEmpty) {
        final availableTimes =
            schedules.map((s) => _normalizeTime(s.startTime)).toSet();
        if (normalizedSelectedTime.isNotEmpty &&
            !availableTimes.contains(normalizedSelectedTime)) {
          _availableSchedules = [
            MassSchedule(
              parishId: _intention?.parishId ?? 0,
              dayOfWeek: _getDayName(date.weekday),
              startTime: normalizedSelectedTime,
              endTime: normalizedSelectedTime,
              isActive: true,
            ),
            ...schedules,
          ];
        }
        _noSchedulesMessage = '';
      } else if (allSchedules.isEmpty) {
        _noSchedulesMessage =
            'No mass schedules configured for ${_getDayName(date.weekday)}. Please select another date or contact the parish office.';
      } else if (schedules.isEmpty && isToday) {
        _noSchedulesMessage =
            'Intention cutoff time has passed for all masses today. Please select another date.';
      }
    });
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _selectedTime = null;
        _availableSchedules.clear();
      });
      _loadSchedulesForDate(picked);
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
    if (widget.massIntentionId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid ID')));
      return;
    }

    String mapType(String frontendType) {
      switch (frontendType) {
        case 'Thanksgiving':
          return 'Thanksgiving';
        case 'Petition':
          return 'Special Intention';
        case 'Soul / Death Anniversary':
          return 'For the Dead';
        case 'Healing':
          return 'Special Intention';
        case 'Special Intention':
        default:
          return 'Special Intention';
      }
    }

    setState(() => _isSaving = true);

    try {
      // Prepare notes array if a new note was added
      final note = Note.fromInput(
        text: _newNoteController.text,
        currentUser: context.read<AuthProvider>().currentUser,
      );

      final notesToAdd = note == null ? null : [note.toJson()];

      final result = await _massIntentionService.updateMassIntention(
        id: widget.massIntentionId!,
        type: mapType(_selectedType!),
        intentionDetails: _intentionForController.text.trim(),
        donorName: _offeredByController.text.trim(),
        preferredDate: _dateController.text,
        parishId: _intention?.parishId ?? 0,
        massSchedule: _dateController.text,
        preferredTimeSlot: _normalizeTime(_selectedTime!.trim()),
        notes: notesToAdd,
      );

      if (!mounted) return;

      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Mass intention updated successfully')));
        _newNoteController.clear();
        _toggleEditMode();
        await _loadMassIntention();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Failed to update')));
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
    if (widget.massIntentionId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')));
      return;
    }

    context.handleBookingStatusUpdate(
      _massIntentionService.updateMassIntentionStatus(
        id: widget.massIntentionId!,
        status: status,
      ),
      status,
    );
  }

  Future<void> _resubmitMassIntention(dynamic currentUser) async {
    if (widget.massIntentionId == null) return;

    setState(() => _isSaving = true);

    try {
      final isParishioner = currentUser?.role == 'parishioner';

      List<Map<String, dynamic>>? notes;
      if (_newNoteController.text.trim().isNotEmpty) {
        notes = [
          {
            'author': isParishioner ? 'parishioner' : 'user',
            'content': _newNoteController.text.trim(),
            'authorId': currentUser?.id,
          }
        ];
      }

      // Use updateMassIntention with status='pending' to resubmit
      String mapTypeForResubmit(String? frontendType) {
        switch (frontendType) {
          case 'Thanksgiving':
            return 'Thanksgiving';
          case 'Petition':
            return 'Special Intention';
          case 'Soul / Death Anniversary':
            return 'For the Dead';
          case 'Healing':
            return 'Special Intention';
          case 'Special Intention':
          default:
            return 'Special Intention';
        }
      }

      final result = await _massIntentionService.updateMassIntention(
        id: widget.massIntentionId!,
        type: mapTypeForResubmit(_selectedType),
        intentionDetails: _intentionForController.text.trim(),
        donorName: _offeredByController.text.trim(),
        preferredDate: _dateController.text,
        parishId: _intention?.parishId ?? 0,
        massSchedule: _dateController.text,
        preferredTimeSlot: _normalizeTime(_selectedTime!.trim()),
        notes: notes,
        status: 'pending',
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Mass intention resubmitted successfully')));
          _newNoteController.clear();
          await _loadMassIntention();
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

  String _formatTimeDisplay(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
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
    final isOwner = _intention?.userId == currentUser?.id;
    final status = _intention?.status?.toLowerCase();
    final canEdit =
        isAdmin || (isOwner && (status == 'pending' || status == 'declined'));

    return Scaffold(
      appBar: AppBar(
        title:
            BookingDetailTitle(title: 'Mass Intention Details', status: status),
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
                      title: "Intention Details",
                      children: [
                        BookingDropdown<String>(
                          initialValue: _selectedType,
                          label: "Intention Type *",
                          hint: const Text("Select an intention type"),
                          validator: Validators.requiredField,
                          enabled: _isEditMode,
                          items: const [
                            'Thanksgiving',
                            'Petition',
                            'Soul / Death Anniversary',
                            'Healing',
                            'Special Intention',
                          ]
                              .map(
                                (label) => DropdownMenuItem<String>(
                                  value: label,
                                  child: Text(label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedType = value!);
                          },
                        ),
                        BookingTextField(
                          controller: _intentionForController,
                          label: "Name of Person / Intention *",
                          validator: Validators.requiredField,
                          enabled: _isEditMode,
                        ),
                        BookingTextField(
                          controller: _offeredByController,
                          label: "Offered By (Name/Family) *",
                          validator: Validators.requiredField,
                          enabled: _isEditMode,
                        ),
                      ],
                    ),
                    BookingSection(
                      title: 'Booking Preferences',
                      children: [
                        BookingTextField(
                          enabled: false,
                          controller: _parishNameController,
                          label: "Preferred Parish *",
                        ),
                        BookingDateField(
                          enabled: _isEditMode,
                          controller: _dateController,
                          label: "Preferred Mass Date *",
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          validator: Validators.requiredField,
                          onTap: () async {
                            await _selectDate();
                          },
                        ),
                        if (_noSchedulesMessage.isNotEmpty &&
                            _selectedDate != null &&
                            _availableSchedules.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _noSchedulesMessage,
                                    style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        BookingDropdown<String>(
                          initialValue: _selectedTime,
                          label: "Mass Time *",
                          hint: const Text("Select a mass time"),
                          disabledHint:
                              const Text("Select a parish and date first"),
                          enabled: _isEditMode &&
                              _selectedDate != null &&
                              _availableSchedules.isNotEmpty,
                          items: _availableSchedules
                              .fold<Map<String, MassSchedule>>({}, (map, s) {
                                final normalized = _normalizeTime(s.startTime);
                                if (!map.containsKey(normalized)) {
                                  map[normalized] = s;
                                }
                                return map;
                              })
                              .values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: _normalizeTime(s.startTime),
                                  child: Text(
                                    '${_formatTimeDisplay(s.startTime)} - '
                                    '${_formatTimeDisplay(s.endTime)}'
                                    // ignore: prefer_interpolation_to_compose_strings
                                    '${s.notes != null ? ' (' + s.notes! + ')' : ''}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedTime = value),
                          validator: (value) => value == null
                              ? "Please select a mass time"
                              : null,
                        ),
                      ],
                    ),

                    // Display existing notes
                    if (_intention?.notes != null &&
                        _intention!.notes!.isNotEmpty)
                      NotesDisplay(notes: _intention!.notes!),

                    // Add new note field (only in edit mode)
                    if (_isEditMode) ...[
                      AdditionalInformationSection(
                        notesController: _newNoteController,
                      ),
                    ],

                    // Resubmit button for declined status (owner only)
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final currentUser = authProvider.currentUser;
                        final isOwner = _intention?.userId == currentUser?.id;
                        final status = _intention?.status?.toLowerCase();

                        if (status == 'declined' && isOwner) {
                          return Column(
                            children: [
                              const SizedBox(height: 20),
                              Card(
                                color: Colors.orange.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Your mass intention was declined. Please make the necessary changes and resubmit.',
                                        style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          icon: _isSaving
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white))
                                              : const Icon(Icons.refresh),
                                          label: Text(_isSaving
                                              ? 'Resubmitting...'
                                              : 'Resubmit'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: _isSaving
                                              ? null
                                              : () => _resubmitMassIntention(
                                                  currentUser),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    BookingStatusActionsSection(
                      visible: isAdmin && !_isEditMode,
                      status: _intention?.status ?? 'pending',
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
    _intentionForController.dispose();
    _offeredByController.dispose();
    _dateController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }
}
