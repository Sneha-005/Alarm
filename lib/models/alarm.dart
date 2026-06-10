import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Alarm {
  final String id;
  final String label;
  final DateTime scheduledAt;
  final bool isEnabled;
  final DateTime createdAt;

  const Alarm({
    required this.id,
    required this.label,
    required this.scheduledAt,
    required this.isEnabled,
    required this.createdAt,
  });

  factory Alarm.fromMap(Map<String, dynamic> map, String id) {
    final dynamic timestamp = map['scheduledAt'];
    final dynamic createdAtValue = map['createdAt'];
    final scheduledAt =
        timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now();
    final createdAt =
        createdAtValue is Timestamp
            ? createdAtValue.toDate()
            : DateTime.tryParse(createdAtValue?.toString() ?? '') ??
                DateTime.now();

    return Alarm(
      id: id,
      label: map['label']?.toString() ?? 'Alarm',
      scheduledAt: scheduledAt,
      isEnabled: map['isEnabled'] == true,
      createdAt: createdAt,
    );
  }

  factory Alarm.fromFirestore(DocumentSnapshot doc) {
    return Alarm.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'isEnabled': isEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Alarm copyWith({
    String? id,
    String? label,
    DateTime? scheduledAt,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return Alarm(
      id: id ?? this.id,
      label: label ?? this.label,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeLabel => DateFormat.jm().format(scheduledAt);

  static List<Alarm> decodeList(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map(
          (item) =>
              Alarm.fromMap(item as Map<String, dynamic>, item['id'] as String),
        )
        .toList();
  }

  static String encodeList(List<Alarm> alarms) {
    final list =
        alarms
            .map(
              (alarm) => {
                'id': alarm.id,
                'label': alarm.label,
                'scheduledAt': alarm.scheduledAt.toIso8601String(),
                'isEnabled': alarm.isEnabled,
                'createdAt': alarm.createdAt.toIso8601String(),
              },
            )
            .toList();
    return jsonEncode(list);
  }
}
