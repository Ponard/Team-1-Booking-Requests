import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/mass_schedule_provider.dart';
import '../models/mass_schedule.dart';
import '../utils/sacrament_icons.dart';

class AdminMassScheduleScreen extends StatefulWidget {
  const AdminMassScheduleScreen({super.key});

  @override
  State<AdminMassScheduleScreen> createState() =>
      _AdminMassScheduleScreenState();
}

class _AdminMassScheduleScreenState extends State<AdminMassScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedules();
    });
  }

  Future<void> _loadSchedules() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parishProvider = Provider.of<ParishProvider>(context, listen: false);
    final scheduleProvider =
        Provider.of<MassScheduleProvider>(context, listen: false);

    await parishProvider.loadAllParishes();

    int? parishId;
    final user = authProvider.currentUser;
    if (user != null && ['parish_admin', 'parish_staff'].contains(user.role)) {
      parishId = user.effectiveParishId;
    }

    await scheduleProvider.loadSchedules(parishId: parishId);
  }

  void _showScheduleForm({MassSchedule? schedule}) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleFormDialog(
        schedule: schedule,
        onSave: () {
          Navigator.pop(context);
          _loadSchedules();
        },
      ),
    );
  }

  Future<void> _deleteSchedule(MassSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text(
            'Are you sure you want to delete the ${schedule.dayOfWeek} ${schedule.startTime} mass schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider =
          Provider.of<MassScheduleProvider>(context, listen: false);
      final success = await provider.deleteSchedule(schedule.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Schedule deleted' : 'Failed to delete schedule'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(MassSchedule schedule) async {
    final provider = Provider.of<MassScheduleProvider>(context, listen: false);
    final success = await provider.updateSchedule(
      id: schedule.id!,
      isActive: !schedule.isActive,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Schedule ${schedule.isActive ? 'deactivated' : 'activated'}'
              : 'Failed to update schedule'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mass Schedule Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Schedule',
            onPressed: () => _showScheduleForm(),
          ),
        ],
      ),
      body: Consumer<MassScheduleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSchedules,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No mass schedules configured',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showScheduleForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Schedule'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadSchedules,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.schedules.length,
              itemBuilder: (context, index) {
                final schedule = provider.schedules[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: schedule.isActive
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        getSacramentIcon('mass_intention'),
                        color: schedule.isActive
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                    ),
                    title: Text(
                      '${schedule.dayOfWeek} - ${_formatTime(schedule.startTime)} to ${_formatTime(schedule.endTime)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: schedule.isActive ? null : Colors.grey,
                        decoration: schedule.isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (schedule.parishName != null)
                          Text('Parish: ${schedule.parishName}'),
                        if (schedule.priestName != null)
                          Text('Priest: ${schedule.priestName}'),
                        if (schedule.intentionCutoffTime != null)
                          Text(
                              'Intention cutoff: ${_formatTime(schedule.intentionCutoffTime!)}'),
                        if (schedule.notes != null) Text(schedule.notes!),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: schedule.isActive,
                          onChanged: (_) => _toggleActive(schedule),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _showScheduleForm(schedule: schedule),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20, color: Colors.red),
                          onPressed: () => _deleteSchedule(schedule),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(String time) {
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
}

class _ScheduleFormDialog extends StatefulWidget {
  final MassSchedule? schedule;
  final VoidCallback onSave;

  const _ScheduleFormDialog({this.schedule, required this.onSave});

  @override
  State<_ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<_ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final Set<String> _selectedDays = {};
  final TextEditingController _cutoffController = TextEditingController();
  String? _startTime;
  String? _endTime;
  String? _notes;
  int? _selectedParishId;
  int? _selectedPriestId;

  String _stripSeconds(String time) {
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }

  String? _calculateCutoff(String startTime) {
    try {
      final parts = startTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final totalMinutes = hour * 60 + minute - 30;
      if (totalMinutes < 0) return '00:00';
      final newHour = totalMinutes ~/ 60;
      final newMinute = totalMinutes % 60;
      return '${newHour.toString().padLeft(2, '0')}:${newMinute.toString().padLeft(2, '0')}';
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _selectedDays.add(widget.schedule!.dayOfWeek);
      _startTime = _stripSeconds(widget.schedule!.startTime);
      _endTime = _stripSeconds(widget.schedule!.endTime);
      _cutoffController.text = widget.schedule!.intentionCutoffTime != null
          ? _stripSeconds(widget.schedule!.intentionCutoffTime!)
          : '';
      _notes = widget.schedule!.notes;
      _selectedParishId = widget.schedule!.parishId;
      _selectedPriestId = widget.schedule!.priestId;
    }
  }

  @override
  void dispose() {
    _cutoffController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one day'),
            backgroundColor: Colors.red),
      );
      return;
    }
    _formKey.currentState!.save();

    final provider = Provider.of<MassScheduleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    int parishId;
    if (user != null && ['parish_admin', 'parish_staff'].contains(user.role)) {
      parishId = user.effectiveParishId!;
    } else {
      parishId = _selectedParishId!;
    }

    bool allSuccess = true;
    final cutoffValue =
        _cutoffController.text.isNotEmpty ? _cutoffController.text : null;
    for (final day in _selectedDays) {
      bool success;
      if (widget.schedule != null) {
        success = await provider.updateSchedule(
          id: widget.schedule!.id!,
          parishId: parishId,
          dayOfWeek: day,
          startTime: _startTime!,
          endTime: _endTime!,
          priestId: _selectedPriestId,
          intentionCutoffTime: cutoffValue,
          notes: _notes,
        );
      } else {
        success = await provider.createSchedule(
          parishId: parishId,
          dayOfWeek: day,
          startTime: _startTime!,
          endTime: _endTime!,
          priestId: _selectedPriestId,
          intentionCutoffTime: cutoffValue,
          notes: _notes,
        );
      }
      if (!success) allSuccess = false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allSuccess
              ? 'Schedule${_selectedDays.length > 1 ? 's' : ''} ${widget.schedule != null ? 'updated' : 'created'}'
              : 'Some schedules failed to save'),
          backgroundColor: allSuccess ? Colors.green : Colors.red,
        ),
      );
      if (allSuccess) widget.onSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isParishLevel =
        user != null && ['parish_admin', 'parish_staff'].contains(user.role);

    return AlertDialog(
      title: Text(widget.schedule != null ? 'Edit Schedule' : 'Add Schedule'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isParishLevel)
                  Consumer<ParishProvider>(
                    builder: (context, parishProvider, _) {
                      final validParishId = _selectedParishId != null &&
                              parishProvider.parishes
                                  .any((p) => p.id == _selectedParishId)
                          ? _selectedParishId
                          : null;
                      return DropdownButtonFormField<int>(
                        initialValue: validParishId,
                        decoration: const InputDecoration(
                          labelText: 'Parish',
                          border: OutlineInputBorder(),
                        ),
                        items: parishProvider.parishes
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedParishId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Days of Week *',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _daysOfWeek.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day.substring(0, 3)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _startTime,
                        decoration: const InputDecoration(
                          labelText: 'Start Time (HH:MM)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                        onChanged: (v) {
                          _startTime = v;
                          final cutoff = _calculateCutoff(v);
                          if (cutoff != null) {
                            _cutoffController.text = cutoff;
                          }
                        },
                        onSaved: (v) => _startTime = v,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(v)) return 'Format: HH:MM';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _endTime,
                        decoration: const InputDecoration(
                          labelText: 'End Time (HH:MM)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                        onSaved: (v) => _endTime = v,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(v)) return 'Format: HH:MM';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cutoffController,
                  decoration: const InputDecoration(
                    labelText: 'Intention Cutoff Time (HH:MM)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onSaved: (v) => _notes = v,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
