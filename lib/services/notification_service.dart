import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alarm.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    debugPrint('NotificationService initialized');
    await _requestPermissions();
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> _requestPermissions() async {
    try {
      final iosPlugin =
          _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('iOS notification permissions requested');

      final androidPlugin =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidPlugin?.requestPermission();
      debugPrint('Android POST_NOTIFICATIONS permission requested');

      _requestExactAlarmsPermissionNative();
    } catch (error, stackTrace) {
      debugPrint('Notification permission request failed: $error');
      debugPrint('$stackTrace');
    }
  }

  void _requestExactAlarmsPermissionNative() {
    const platform = MethodChannel('com.example.alarm/alarm');
    try {
      platform.invokeMethod<void>('requestExactAlarmsPermission');
      debugPrint('Android SCHEDULE_EXACT_ALARM permission requested via native');
    } catch (error) {
      debugPrint('Failed to request exact alarms permission: $error');
    }
  }

  int _notificationId(String alarmId) {
    return alarmId.hashCode & 0x7fffffff;
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    debugPrint('scheduleAlarm() called');
    await cancelAlarm(alarm.id);
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.scheduledAt.hour,
      alarm.scheduledAt.minute,
    );

    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        channelDescription: 'Notifications for scheduled alarms',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      debugPrint(
        'Scheduling alarm: id=${alarm.id}, label=${alarm.label}, time=${scheduledDate}',
      );
      await _plugin.schedule(
        _notificationId(alarm.id),
        alarm.label.isNotEmpty ? alarm.label : 'Alarm',
        'Alarm set for ${alarm.timeLabel}',
        scheduledDate,
        notificationDetails,
        androidAllowWhileIdle: true,
      );
      debugPrint('Alarm scheduled successfully: ${alarm.id}');
    } catch (error, stackTrace) {
      if (error is PlatformException &&
          error.code == 'exact_alarms_not_permitted') {
        debugPrint(
          'Exact alarms permission not granted, will use inexact scheduling',
        );
        debugPrint('$error');
      } else {
        debugPrint('Error scheduling alarm: $error');
        debugPrint('$stackTrace');
        rethrow;
      }
    }
  }

  Future<void> cancelAlarm(String alarmId) {
    return _plugin.cancel(_notificationId(alarmId));
  }

  Future<void> cancelAll() {
    return _plugin.cancelAll();
  }
}
