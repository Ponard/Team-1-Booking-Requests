import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_date_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/parish_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_controller.dart';
import 'package:diocese_frontend/widgets/booking_forms/form/booking_form_scope.dart';
import 'package:diocese_frontend/widgets/booking_forms/sections/additional_information_section.dart';
import 'package:diocese_frontend/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/mass_intention_provider.dart';
import '../providers/mass_schedule_provider.dart';
import '../models/mass_schedule.dart';

class MassIntentionScreen extends StatefulWidget {
  const MassIntentionScreen({super.key});

  @override
  State<MassIntentionScreen> createState() => _MassIntentionScreenState();
}

class _MassIntentionScreenState extends State<MassIntentionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bookingFormController = BookingFormController();

  final TextEditingController _offeredByController = TextEditingController();
  final TextEditingController _intentionForController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedType;
  String? _selectedTime;
  DateTime? _selectedDate;
  List<MassSchedule> _availableSchedules = [];
  String _noSchedulesMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final parishProvider =
          Provider.of<ParishProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      parishProvider.clearSelection();
      await parishProvider.loadParishesByService(
        'mass_intention',
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
    _offeredByController.dispose();
    _intentionForController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
      _loadSchedulesForDate(picked);
    }
  }

  Future<void> _loadSchedulesForDate(DateTime date) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parishProvider = Provider.of<ParishProvider>(context, listen: false);
    final scheduleProvider =
        Provider.of<MassScheduleProvider>(context, listen: false);

    int? parishId;
    if (parishProvider.selectedParish != null) {
      parishId = parishProvider.selectedParish!.id;
    } else if (authProvider.currentUser?.effectiveParishId != null) {
      parishId = authProvider.currentUser!.effectiveParishId;
    }

    await scheduleProvider.loadSchedules(parishId: parishId);
    List<MassSchedule> schedules = scheduleProvider.getSchedulesForDate(date);

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

    setState(() {
      _availableSchedules = schedules;
      _selectedTime = null;
      final allSchedules = scheduleProvider.getSchedulesForDate(date);
      if (allSchedules.isEmpty) {
        _noSchedulesMessage =
            'No mass schedules configured for ${_getDayName(date.weekday)}. Please select another date or contact the parish office.';
      } else if (schedules.isEmpty && isToday) {
        _noSchedulesMessage =
            'Intention cutoff time has passed for all masses today. Please select another date.';
      } else {
        _noSchedulesMessage = '';
      }
    });
  }

  String _normalizeTime(String? time) {
    if (time == null) return '';
    final parts = time.split(':');
    return '${parts[0]}:${parts[1]}';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _bookingFormController.focusFirstInvalid();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final massIntentionProvider =
        Provider.of<MassIntentionProvider>(context, listen: false);
    final parishProvider = Provider.of<ParishProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please login to submit a mass intention.")),
      );
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

    String formatDate(String date) {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
      }
      return date;
    }

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

    final success = await massIntentionProvider.createMassIntention(
      type: mapType(_selectedType!),
      intentionDetails: _intentionForController.text.trim(),
      donorName: _offeredByController.text.trim(),
      preferredDate: formatDate(_dateController.text),
      parishId: parishProvider.selectedParish!.id!,
      preferredTimeSlot: _selectedTime,
      notes: notesToAdd,
    );

    if (success && mounted) {
      _formKey.currentState?.reset();
      Navigator.of(context).pop(true); // Go back
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(massIntentionProvider.errorMessage ??
                "Failed to submit mass intention.")),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mass Intention"),
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
                      "Subject to availability. Parish will confirm your booking.",
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Intention Details
                    BookingSection(
                      title: "Intention Details",
                      children: [
                        BookingDropdown<String>(
                          initialValue: _selectedType,
                          label: "Intention Type *",
                          hint: const Text("Select an intention type"),
                          validator: Validators.requiredField,
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
                        ),
                        BookingTextField(
                          controller: _offeredByController,
                          label: "Offered By (Name/Family) *",
                          validator: Validators.requiredField,
                        ),
                      ],
                    ),

                    // Booking Preferences
                    BookingSection(
                      title: 'Booking Preferences',
                      children: [
                        ParishDropdown(
                          onParishChanged: () {
                            if (_selectedDate != null) {
                              _loadSchedulesForDate(_selectedDate!);
                            }
                          },
                        ),
                        BookingDateField(
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
                        if (_selectedDate != null &&
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
                          enabled: _availableSchedules.isNotEmpty,
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

                    // Additional Information
                    AdditionalInformationSection(
                      notesController: _notesController,
                    ),

                    const SizedBox(height: 20),

                    Consumer<MassIntentionProvider>(
                      builder: (context, provider, _) {
                        return CustomButton(
                          width: double.infinity,
                          text: "Submit Booking",
                          onPressed: _submitForm,
                          isLoading: provider.isLoading,
                        );
                      },
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
}
