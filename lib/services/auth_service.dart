import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/core/roles.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String name,
    required String surname,
    required String email,
    required String password,

    required String role,
  }) async {
    final cred = await _auth
        .createUserWithEmailAndPassword(email: email.trim(), password: password)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            throw TimeoutException(
              'Kayıt isteği zaman aşımına uğradı.',
              const Duration(seconds: 12),
            );
          },
        );

    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Kullanıcı oluşturulamadı.',
      );
    }

    if (!user.emailVerified) {
      unawaited(
        user
            .sendEmailVerification()
            .timeout(const Duration(seconds: 8))
            .catchError((_) {}),
      );
    }

    final normalizedRole = AppRoles.normalize(role);
    // Admin dışındaki onay gerektiren roller uygulamaya girmeden önce panel onayı bekler.
    final status = (normalizedRole == AppRoles.admin)
        ? AppUserStatus.approved
        : (AppRoles.needsApproval(normalizedRole)
              ? AppUserStatus.pending
              : AppUserStatus.approved);

    await _db
        .collection('users')
        .doc(user.uid)
        .set({
          'name': name.trim(),
          'surname': surname.trim(),
          'email': email.trim(),

          'role': normalizedRole,

          'status': status,

          'onboardingDone': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            throw TimeoutException(
              'Kullanıcı profili kaydı zaman aşımına uğradı.',
              const Duration(seconds: 12),
            );
          },
        );

    return cred;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resendVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Oturum bulunamadı.',
      );
    }
    if (user.emailVerified) return;

    await user.sendEmailVerification();
  }

  Future<bool> refreshAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<bool> isOnboardingDone() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();

    return data?['onboardingDone'] == true;
  }

  Future<void> markOnboardingDone() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'onboardingDone': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setUserStatus({
    required String uid,
    required String status,
  }) async {
    await _db.collection('users').doc(uid).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setUserRole({required String uid, required String role}) async {
    await _db.collection('users').doc(uid).set({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() => _auth.signOut();
}
