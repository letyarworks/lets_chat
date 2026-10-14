import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== Email/Password Sign Up ====================
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String language = 'en',
  }) async {
    try {
      // 1. Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Update display name
      await credential.user!.updateDisplayName(displayName);

      // 3. Send email verification
      await credential.user!.sendEmailVerification();

      // 4. Create Firestore user document
      await _createUserDocument(
        userId: credential.user!.uid,
        email: email.trim(),
        displayName: displayName,
        language: language,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== Email/Password Sign In ====================
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
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
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      // ပထမဆုံး Login ဆိုရင် User Document ဖန်တီးပါ
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? 'User',
          phoneNumber: userCredential.user!.phoneNumber,
        );
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== Google Sign In ====================
  Future<UserCredential> signInWithGoogleCredential(
    OAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? 'User',
        );
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== Sign Out ====================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ==================== Password Reset ====================
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== Delete Account ====================
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Delete Firestore user document
      await _firestore.collection('users').doc(user.uid).delete();
      
      // 2. Delete Firebase Auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ==================== Private Helpers ====================
  
  /// Firestore မှာ User Document ဖန်တီးခြင်း
  Future<void> _createUserDocument({
    required String userId,
    required String email,
    required String displayName,
    String? phoneNumber,
    String language = 'en',
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber ?? '',
      'photoURL': '',
      'status': '',
      'language': language,
      'themeMode': 'system',
      'fcmToken': '',
      'blockedUsers': [],
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Firebase Auth Exception ကို User-friendly Message ပြောင်းခြင်း
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'ဒီ Email နဲ့ Account မရှိပါဘူး။';
      case 'wrong-password':
        return 'Password မှားနေပါတယ်။';
      case 'email-already-in-use':
        return 'ဒီ Email ကို အသုံးပြုပြီးသား ဖြစ်နေပါတယ်။';
      case 'invalid-email':
        return 'Email ပုံစံ မမှန်ကန်ပါဘူး။';
      case 'weak-password':
        return 'Password အားနည်းနေပါတယ်။ အနည်းဆုံး ၆ လုံး ထည့်ပါ။';
      case 'too-many-requests':
        return 'အကြိမ်အရေအတွက် ကျော်လွန်နေပါတယ်။ ခဏစောင့်ပြီး ပြန်ကြိုးစားပါ။';
      case 'invalid-verification-code':
        return 'Verification Code မှားနေပါတယ်။';
      case 'invalid-phone-number':
        return 'Phone Number ပုံစံ မမှန်ကန်ပါဘူး။';
      case 'network-request-failed':
        return 'Internet Connection ကို စစ်ဆေးပါ။';
      case 'requires-recent-login':
        return 'ဒီလုပ်ဆောင်ချက်အတွက် ပြန်လည် Login ဝင်ရပါမယ်။';
      default:
        debugPrint('AuthException: ${e.code} - ${e.message}');
        return 'Error ဖြစ်ပွားပါတယ်။ ပြန်ကြိုးစားပါ။';
    }
  }
}