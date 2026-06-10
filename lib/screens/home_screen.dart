import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/alarm_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Alarms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<AlarmProvider>(
        builder: (context, alarmProvider, child) {
          final alarms = alarmProvider.alarms;
          if (alarmProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (alarms.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'No alarms yet. Tap the + button to add one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: alarms.length,
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return AlarmTile(
                alarm: alarm,
                onToggle: (value) {
                  context.read<AlarmProvider>().toggleAlarmEnabled(
                    alarm,
                    value,
                  );
                },
                onDelete: () {
                  context.read<AlarmProvider>().removeAlarm(alarm.id);
                },
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    '/addEdit',
                    arguments: alarm,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/addEdit');
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Alarm',
      ),
    );
  }
}
