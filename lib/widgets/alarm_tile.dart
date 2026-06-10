import 'package:flutter/material.dart';

import '../models/alarm.dart';

class AlarmTile extends StatelessWidget {
  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AlarmTile({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(alarm.label),
        subtitle: Text(alarm.timeLabel),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: alarm.isEnabled, onChanged: onToggle),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete alarm',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
