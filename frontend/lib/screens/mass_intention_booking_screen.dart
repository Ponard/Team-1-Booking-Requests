import 'package:diocese_frontend/utils/validators.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_dropdown.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_section.dart';
import 'package:diocese_frontend/widgets/booking_forms/common/booking_text_field.dart';
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

  final TextEditingController _offeredByController = TextEditingController();
  final TextEditingController _intentionForController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedType = 'Thanksgiving';
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
        _selectedTime = null;
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
      if (schedules.isNotEmpty && _selectedTime == null) {
        _selectedTime = _normalizeTime(schedules.first.startTime);
      }
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
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a mass date.")),
        );
        return;
      }
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a mass time.")),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final massIntentionProvider =
          Provider.of<MassIntentionProvider>(context, listen: false);
      final parishProvider =
          Provider.of<ParishProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please login to submit a mass intention.")),
        );
        return;
      }

      if (parishProvider.selectedParish == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a parish.")),
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
        type: mapType(_selectedType),
        intentionDetails: _intentionForController.text.trim(),
        donorName: _offeredByController.text.trim(),

        //QA Fix: Add trim() to both uses of _dateController
        dateRequested: formatDate(_dateController.text),
        parishId: parishProvider.selectedParish!.id!,
        massSchedule: formatDate(_dateController.text),

        //QA Fix: Add trim() method to the selected time.
        preferredTime: _selectedTime,
        notes: notesToAdd,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Mass Intention Submitted"),
            content: const Text(
                "Your mass intention request has been submitted successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(massIntentionProvider.errorMessage ??
                  "Failed to submit mass intention.")),
        );
      }
    }
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
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

                  // TODO: refactor into BookingSection
                  // Booking Preferences
                  _buildSection(title: "Booking Preferences", children: [
                    Consumer<ParishProvider>(
                      builder: (context, parishProvider, _) {
                        return DropdownButtonFormField<int>(
                          initialValue: parishProvider.selectedParish?.id,
                          decoration: const InputDecoration(
                            labelText: "Preferred Parish *",
                            border: OutlineInputBorder(),
                          ),
                          items: parishProvider.parishes
                              .map((parish) => DropdownMenuItem(
                                    value: parish.id,
                                    child: Text(parish.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            final parish = parishProvider.parishes
                                .firstWhere((p) => p.id == value);
                            parishProvider.selectParish(parish);
                            if (_selectedDate != null) {
                              _loadSchedulesForDate(_selectedDate!);
                            }
                          },
                          validator: (value) =>
                              value == null ? "Please select a parish" : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                          labelText: "Preferred Mass Date *",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today)),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        await _selectDate();
                      },
                      validator: (value) =>
                          value!.isEmpty ? "Please select a date" : null,
                    ),
                    const SizedBox(height: 12),
                    if (_selectedDate != null && _availableSchedules.isEmpty)
                      Container(
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
                    if (_availableSchedules.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTime,
                        decoration: const InputDecoration(
                          labelText: "Mass Time *",
                          border: OutlineInputBorder(),
                        ),
                        items: _availableSchedules
                            .fold<Map<String, MassSchedule>>({}, (map, s) {
                              final normalized = _normalizeTime(s.startTime);
                              if (!map.containsKey(normalized)) {
                                map[normalized] = s;
                              }
                              return map;
                            })
                            .values
                            .map((s) => DropdownMenuItem(
                                  value: _normalizeTime(s.startTime),
                                  child: Text(
                                      '${_formatTimeDisplay(s.startTime)} - ${_formatTimeDisplay(s.endTime)}${s.notes != null ? ' (${s.notes})' : ''}'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedTime = value),
                        validator: (value) =>
                            value == null ? "Please select a mass time" : null,
                      ),
                  ]),

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
