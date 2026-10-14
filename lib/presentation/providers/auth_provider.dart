import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  /// App စတင်တဲ့အခါ Auth State ကို စောင့်ကြည့်ခြင်း
  void _init() {
    _authRepository.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ==================== Sign Up ====================
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String language = 'en',
  }) async {
    _setLoading();
    try {
      await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        language: language,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ==================== Sign In ====================
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ==================== Phone Sign In ====================
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    _setLoading();
    try {
      await _authRepository.signInWithPhoneCredential(credential);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ==================== Google Sign In ====================
  Future<bool> signInWithGoogleCredential(OAuthCredential credential) async {
    _setLoading();
    try {
      await _authRepository.signInWithGoogleCredential(credential);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ==================== Sign Out ====================
  Future<void> signOut() async {
    await _authRepository.signOut();
    _status = AuthStatus.unauthenticated;
    _user = null;
    notifyListeners();
  }

  // ==================== Password Reset ====================
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading();
    try {
      await _authRepository.sendPasswordResetEmail(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ==================== Delete Account ====================
  Future<bool> deleteAccount() async {
    _setLoading();
    try {
      await _authRepository.deleteAccount();
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ==================== Helpers ====================
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_user != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}