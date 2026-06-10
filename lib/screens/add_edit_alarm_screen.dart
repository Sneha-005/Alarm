import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alarm.dart';
import '../providers/alarm_provider.dart';

class AddEditAlarmScreen extends StatefulWidget {
  const AddEditAlarmScreen({super.key});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  DateTime? _selectedTime;
  bool _isEnabled = true;
  Alarm? _editingAlarm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Alarm && _editingAlarm == null) {
      _editingAlarm = args;
      _labelController.text = _editingAlarm!.label;
      _selectedTime = _editingAlarm!.scheduledAt;
      _isEnabled = _editingAlarm!.isEnabled;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final initial =
        _selectedTime != null
            ? TimeOfDay(
              hour: _selectedTime!.hour,
              minute: _selectedTime!.minute,
            )
            : now;
    final result = await showTimePicker(context: context, initialTime: initial);
    if (result != null) {
      setState(() {
        final nowDate = DateTime.now();
        var scheduled = DateTime(
          nowDate.year,
          nowDate.month,
          nowDate.day,
          result.hour,
          result.minute,
        );
        if (scheduled.isBefore(nowDate)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        _selectedTime = scheduled;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a time for the alarm.')),
      );
      return;
    }

    final provider = context.read<AlarmProvider>();
    final alarm = Alarm(
      id: _editingAlarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label:
          _labelController.text.trim().isEmpty
              ? 'Alarm'
              : _labelController.text.trim(),
      scheduledAt: _selectedTime!,
      isEnabled: _isEnabled,
      createdAt: _editingAlarm?.createdAt ?? DateTime.now(),
    );

    await provider.addOrUpdateAlarm(alarm);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _editingAlarm == null ? 'Add Alarm' : 'Edit Alarm';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Label'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an alarm label';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedTime != null
                          ? 'Time: ${TimeOfDay.fromDateTime(_selectedTime!).format(context)}'
                          : 'Choose a time',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickTime,
                    child: const Text('Pick Time'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isEnabled,
                title: const Text('Enabled'),
                onChanged: (value) => setState(() => _isEnabled = value),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Alarm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
