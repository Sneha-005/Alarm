import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/alarm.dart';

class FirebaseService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  FirebaseService() {
    firestore.settings = const Settings(persistenceEnabled: true);
  }

  Stream<User?> authStateChanges() => auth.authStateChanges();

  User? get currentUser => auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register(String email, String password) {
    return auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return auth.signOut();
  }

  CollectionReference<Map<String, dynamic>> _alarms(String uid) {
    return firestore.collection('users').doc(uid).collection('alarms');
  }

  Stream<List<Alarm>> alarmStream(String uid) {
    return _alarms(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Alarm.fromFirestore(doc)).toList(),
        );
  }

  Future<List<Alarm>> fetchAlarmsOnce(String uid) async {
    final snapshot =
        await _alarms(uid).orderBy('createdAt', descending: false).get();
    return snapshot.docs.map((doc) => Alarm.fromFirestore(doc)).toList();
  }

  Future<void> saveAlarm(String uid, Alarm alarm) async {
    try {
      await _alarms(uid).doc(alarm.id).set(alarm.toMap());
    } catch (error, stackTrace) {
      // Surface helpful debug info so callers can log or inspect failures
      debugPrint(
        'FirebaseService.saveAlarm failed for uid=$uid id=${alarm.id}: $error',
      );
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<void> deleteAlarm(String uid, String alarmId) {
    if (alarmId.isEmpty) {
      return Future.error(
        ArgumentError.value(alarmId, 'alarmId', 'Alarm ID must not be empty'),
      );
    }
    return _alarms(uid).doc(alarmId).delete();
  }
}
