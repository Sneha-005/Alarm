import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  User? _user;
  bool isLoading = false;
  String? errorMessage;

  AuthProvider({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService() {
    _firebaseService.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;

  Future<bool> signIn(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      await _firebaseService.signIn(email.trim(), password.trim());
      return true;
    } on FirebaseAuthException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (error, stackTrace) {
      errorMessage = error.toString();
      debugPrint('AuthProvider.signIn error: $error');
      debugPrint('$stackTrace');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      await _firebaseService.register(email.trim(), password.trim());
      return true;
    } on FirebaseAuthException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (error, stackTrace) {
      errorMessage = error.toString();
      debugPrint('AuthProvider.register error: $error');
      debugPrint('$stackTrace');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
  }
}
