import 'package:flutter/material.dart';

import '../../services/parish_settings_service.dart';

class ParishAvailabilitySettingsScreen extends StatefulWidget {
  final int parishId;
  final String parishName;

  const ParishAvailabilitySettingsScreen({
    super.key,
    required this.parishId,
    required this.parishName,
  });

  @override
  State<ParishAvailabilitySettingsScreen> createState() =>
      _ParishAvailabilitySettingsScreenState();
}

class _ParishAvailabilitySettingsScreenState
    extends State<ParishAvailabilitySettingsScreen> {
  static const _services = <String, String>{
    'baptism': 'Baptism',
    'wedding': 'Wedding',
    'confirmation': 'Confirmation',
    'eucharist': 'Eucharist',
    'reconciliation': 'Reconciliation',
    'anointing_sick': 'Anointing of the Sick',
    'funeral_mass': 'Funeral Mass',
    'mass_intention': 'Mass Intention',
  };

  final _formKey = GlobalKey<FormState>();
  final _dailyController = TextEditingController();
  final _weeklyController = TextEditingController();
  final _minDaysController = TextEditingController(text: '1');
  final _maxDaysController = TextEditingController(text: '90');

  String _serviceType = 'baptism';
  String? _cutoffTime;
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;
  bool _hasSetting = false;

  List<Map<String, dynamic>> _settings = [];
  List<Map<String, dynamic>> _blackouts = [];
  List<Map<String, dynamic>> _slots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _weeklyController.dispose();
    _minDaysController.dispose();
    _maxDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ParishSettingsService.getSlotSettings(widget.parishId),
        ParishSettingsService.getBlackoutDates(widget.parishId),
      ]);

      if (!mounted) return;
      _settings = results[0];
      _blackouts = results[1];
      _selectService(_serviceType);
    } catch (e) {
      if (mounted) _showMessage(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectService(String type) {
    _serviceType = type;
    final matches = _settings.where((s) => s['serviceType'] == type);
    final setting = matches.isEmpty ? null : matches.first;

    _hasSetting = setting != null;
    _dailyController.text = setting?['dailyLimit']?.toString() ?? '';
    _weeklyController.text = setting?['weeklyLimit']?.toString() ?? '';
    _minDaysController.text = (setting?['minAdvanceDays'] ?? 1).toString();
    _maxDaysController.text = (setting?['maxAdvanceDays'] ?? 90).toString();
    _cutoffTime = setting?['cutoffTime']?.toString().substring(0, 5);
    _isActive = setting?['isActive'] ?? true;
    _slots = List<Map<String, dynamic>>.from(
      (setting?['timeSlots'] as List? ?? []).map(
        (slot) => Map<String, dynamic>.from(slot as Map),
      ),
    );
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final daily = _dailyController.text.trim();
      final weekly = _weeklyController.text.trim();

      await ParishSettingsService.saveSlotSettings(widget.parishId, {
        'serviceType': _serviceType,
        'dailyLimit': daily.isEmpty ? null : int.parse(daily),
        'weeklyLimit': weekly.isEmpty ? null : int.parse(weekly),
        'minAdvanceDays': int.parse(_minDaysController.text),
        'maxAdvanceDays': int.parse(_maxDaysController.text),
        'cutoffTime': _cutoffTime,
        'timeSlots': _slots,
        'isActive': _isActive,
      });

      await _loadData();
      if (mounted) _showMessage('Scheduling settings saved.');
    } catch (e) {
      if (mounted) _showMessage(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteSettings() async {
    final confirmed = await _confirm(
      'Delete scheduling settings?',
      'This removes the saved configuration for '
          '${_services[_serviceType]}.',
    );
    if (!confirmed) return;

    try {
      await ParishSettingsService.deleteSlotSettings(
        widget.parishId,
        _serviceType,
      );
      await _loadData();
      if (mounted) _showMessage('Scheduling settings deleted.');
    } catch (e) {
      if (mounted) _showMessage(e.toString(), error: true);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _pickTime({String? initial}) async {
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    if (initial != null && initial.length >= 5) {
      final parts = initial.substring(0, 5).split(':');
      start = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    final selected = await showTimePicker(
      context: context,
      initialTime: start,
    );
    if (selected == null) return null;

    return '${selected.hour.toString().padLeft(2, '0')}:'
        '${selected.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _addSlot() async {
    final start = await _pickTime();
    if (start == null || !mounted) return;

    final end = await _pickTime(initial: start);
    if (end == null || !mounted) return;

    if (end.compareTo(start) <= 0) {
      _showMessage('End time must be later than start time.', error: true);
      return;
    }

    final capacity = await _askCapacity();
    if (capacity == null || !mounted) return;

    setState(() {
      _slots.add({'start': start, 'end': end, 'capacity': capacity});
      _slots.sort(
          (a, b) => (a['start'] as String).compareTo(b['start'] as String));
    });
  }

  Future<int?> _askCapacity({int initial = 1}) async {
    final controller = TextEditingController(text: initial.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slot capacity'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Bookings allowed',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value == null || value < 1) return;
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _editSlot(int index) async {
    final old = _slots[index];
    final capacity = await _askCapacity(
      initial: (old['capacity'] as num?)?.toInt() ?? 1,
    );
    if (capacity == null || !mounted) return;

    setState(() {
      _slots[index] = {...old, 'capacity': capacity};
    });
  }

  Future<void> _showBlackoutDialog({Map<String, dynamic>? existing}) async {
    final dateController = TextEditingController(
      text: existing?['date']?.toString() ??
          DateTime.now().toIso8601String().substring(0, 10),
    );
    final reasonController = TextEditingController(
      text: existing?['reason']?.toString() ?? '',
    );
    String? service = existing?['serviceType']?.toString();
    bool recurring = existing?['isRecurring'] == true;
    String pattern = existing?['recurrencePattern']?.toString() ?? 'yearly';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              existing == null ? 'Add blackout date' : 'Edit blackout date'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final current = DateTime.tryParse(dateController.text) ??
                        DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: current,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      dateController.text =
                          picked.toIso8601String().substring(0, 10);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: service,
                  decoration: const InputDecoration(
                    labelText: 'Applies to',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All services'),
                    ),
                    ..._services.entries.map(
                      (e) => DropdownMenuItem<String?>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => service = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeat this date'),
                  value: recurring,
                  onChanged: (value) =>
                      setDialogState(() => recurring = value ?? false),
                ),
                if (recurring)
                  DropdownButtonFormField<String>(
                    initialValue: pattern,
                    decoration: const InputDecoration(
                      labelText: 'Repeat pattern',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                      DropdownMenuItem(
                          value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => pattern = value);
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (DateTime.tryParse(dateController.text) == null) return;
                Navigator.pop(dialogContext, {
                  'date': dateController.text,
                  'serviceType': service,
                  'reason': reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                  'isRecurring': recurring,
                  'recurrencePattern': recurring ? pattern : null,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    dateController.dispose();
    reasonController.dispose();

    if (result == null || !mounted) return;

    try {
      final id = (existing?['id'] as num?)?.toInt();
      await ParishSettingsService.saveBlackoutDate(
        widget.parishId,
        result,
        id: id,
      );
      await _loadData();
      if (mounted) _showMessage('Blackout date saved.');
    } catch (e) {
      if (mounted) _showMessage(e.toString(), error: true);
    }
  }

  Future<void> _deleteBlackout(Map<String, dynamic> blackout) async {
    final id = (blackout['id'] as num?)?.toInt();
    if (id == null) return;

    final confirmed = await _confirm(
      'Delete blackout date?',
      'This will remove ${blackout['date']}.',
    );
    if (!confirmed) return;

    try {
      await ParishSettingsService.deleteBlackoutDate(widget.parishId, id);
      await _loadData();
      if (mounted) _showMessage('Blackout date deleted.');
    } catch (e) {
      if (mounted) _showMessage(e.toString(), error: true);
    }
  }

  Widget _numberField(
    String label,
    TextEditingController controller, {
    bool optional = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        helperText: optional ? 'Leave blank for no limit' : null,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return optional ? null : 'Required';
        }
        final number = int.tryParse(value);
        if (number == null || number < 0) return 'Enter a valid number';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parish Availability'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(widget.parishName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Configure booking capacity and unavailable dates.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Text('Scheduling settings',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _serviceType,
                    decoration: const InputDecoration(
                      labelText: 'Sacrament / service',
                      border: OutlineInputBorder(),
                    ),
                    items: _services.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectService(value));
                    },
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                'Daily limit',
                                _dailyController,
                                optional: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _numberField(
                                'Weekly limit',
                                _weeklyController,
                                optional: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                'Minimum advance days',
                                _minDaysController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _numberField(
                                'Maximum advance days',
                                _maxDaysController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  _cutoffTime == null
                                      ? 'Set cutoff time'
                                      : 'Cutoff: $_cutoffTime',
                                ),
                                onPressed: () async {
                                  final time = await _pickTime(
                                    initial: _cutoffTime,
                                  );
                                  if (time != null && mounted) {
                                    setState(() => _cutoffTime = time);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: 'Clear cutoff time',
                              onPressed: () =>
                                  setState(() => _cutoffTime = null),
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Scheduling active'),
                          subtitle: const Text(
                            'Inactive settings are not returned by the active configuration endpoint.',
                          ),
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Time slots',
                            style: theme.textTheme.titleMedium),
                      ),
                      TextButton.icon(
                        onPressed: _addSlot,
                        icon: const Icon(Icons.add),
                        label: const Text('Add slot'),
                      ),
                    ],
                  ),
                  if (_slots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No time slots configured. Add a slot to define '
                        'the available booking times.',
                      ),
                    )
                  else
                    ..._slots.asMap().entries.map((entry) {
                      final index = entry.key;
                      final slot = entry.value;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.schedule),
                          title: Text('${slot['start']} – ${slot['end']}'),
                          subtitle: Text(
                            'Capacity: ${slot['capacity'] ?? 1}',
                          ),
                          onTap: () => _editSlot(index),
                          trailing: IconButton(
                            tooltip: 'Remove slot',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => _slots.removeAt(index)),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveSettings,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label:
                        Text(_saving ? 'Saving…' : 'Save scheduling settings'),
                  ),
                  if (_hasSetting)
                    TextButton(
                      onPressed: _deleteSettings,
                      child: const Text('Delete settings for this service'),
                    ),
                  const Divider(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Blackout dates',
                            style: theme.textTheme.titleLarge),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _showBlackoutDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_blackouts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No blackout dates configured.'),
                    )
                  else
                    ..._blackouts.map((blackout) {
                      final service = blackout['serviceType'] as String?;
                      final label = service == null
                          ? 'All services'
                          : _services[service] ?? service;
                      final recurring = blackout['isRecurring'] == true;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_busy),
                          title: Text(blackout['date']?.toString() ?? ''),
                          subtitle: Text(
                            '$label'
                            '${blackout['reason'] == null ? '' : '\n${blackout['reason']}'}'
                            '${recurring ? '\nRepeats ${blackout['recurrencePattern']}' : ''}',
                          ),
                          isThreeLine: blackout['reason'] != null || recurring,
                          onTap: () => _showBlackoutDialog(existing: blackout),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showBlackoutDialog(existing: blackout);
                              } else if (value == 'delete') {
                                _deleteBlackout(blackout);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
