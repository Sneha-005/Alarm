import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AlarmProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final NotificationService _notificationService;
  final SharedPreferences _prefs;
  StreamSubscription<List<Alarm>>? _remoteSubscription;
  User? _user;

  List<Alarm> _alarms = [];
  bool isLoading = false;

  AlarmProvider({
    required FirebaseService firebaseService,
    required NotificationService notificationService,
    required SharedPreferences sharedPreferences,
  }) : _firebaseService = firebaseService,
       _notificationService = notificationService,
       _prefs = sharedPreferences {
    _loadLocalAlarms();
  }

  List<Alarm> get alarms => List.unmodifiable(_alarms);

  void setUser(User? user) {
    if (_user?.uid == user?.uid) {
      return;
    }
    _user = user;
    _remoteSubscription?.cancel();
    if (_user != null) {
      _subscribeToRemoteAlarms();
    }
    notifyListeners();
  }

  Future<void> _loadLocalAlarms() async {
    final cached = _prefs.getString('alarms_cache');
    if (cached != null && cached.isNotEmpty) {
      try {
        _alarms = Alarm.decodeList(cached);
      } catch (_) {
        _alarms = [];
      }
    }
    _scheduleEnabledAlarms();
    notifyListeners();
  }

  Future<void> _saveLocalAlarms() async {
    await _prefs.setString('alarms_cache', Alarm.encodeList(_alarms));
  }

  Future<void> addOrUpdateAlarm(Alarm alarm) async {
    final index = _alarms.indexWhere((item) => item.id == alarm.id);
    if (index >= 0) {
      _alarms[index] = alarm;
    } else {
      _alarms.add(alarm);
    }
    await _saveLocalAlarms();
    _scheduleAlarm(alarm);
    if (_user != null) {
      try {
        await _firebaseService.saveAlarm(_user!.uid, alarm);
      } catch (error, stackTrace) {
        debugPrint('Failed to save alarm to Firestore: $error');
        debugPrint('$stackTrace');
      }
    }
    notifyListeners();
  }

  Future<void> removeAlarm(String alarmId) async {
    _alarms.removeWhere((alarm) => alarm.id == alarmId);
    await _saveLocalAlarms();
    await _notificationService.cancelAlarm(alarmId);
    if (_user != null) {
      try {
        await _firebaseService.deleteAlarm(_user!.uid, alarmId);
      } catch (error, stackTrace) {
        debugPrint('Failed to delete alarm from Firestore: $error');
        debugPrint('$stackTrace');
      }
    }
    notifyListeners();
  }

  Future<void> toggleAlarmEnabled(Alarm alarm, bool isEnabled) async {
    final updated = alarm.copyWith(isEnabled: isEnabled);
    await addOrUpdateAlarm(updated);
  }

  Future<void> _subscribeToRemoteAlarms() async {
    if (_user == null) return;
    _remoteSubscription = _firebaseService.alarmStream(_user!.uid).listen((
      remoteAlarms,
    ) async {
      final localMap = {for (final alarm in _alarms) alarm.id: alarm};
      for (final remote in remoteAlarms) {
        localMap[remote.id] = remote;
      }
      _alarms =
          localMap.values.toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      await _saveLocalAlarms();
      _scheduleEnabledAlarms();
      notifyListeners();
    });
    await _uploadLocalAlarmsToFirestore();
  }

  Future<void> _uploadLocalAlarmsToFirestore() async {
    if (_user == null) return;
    final remoteAlarms = await _firebaseService.fetchAlarmsOnce(_user!.uid);
    final remoteIds = remoteAlarms.map((alarm) => alarm.id).toSet();
    for (final alarm in _alarms) {
      if (!remoteIds.contains(alarm.id)) {
        await _firebaseService.saveAlarm(_user!.uid, alarm);
      }
    }
  }

  void _scheduleEnabledAlarms() {
    for (final alarm in _alarms) {
      if (alarm.isEnabled) {
        _scheduleAlarm(alarm);
      } else {
        _notificationService.cancelAlarm(alarm.id);
      }
    }
  }

  Future<void> _scheduleAlarm(Alarm alarm) async {
    if (alarm.isEnabled) {
      await _notificationService.scheduleAlarm(alarm);
    } else {
      await _notificationService.cancelAlarm(alarm.id);
    }
  }
}
