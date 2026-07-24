import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';

import 'waiting_approval_page.dart';
import 'rejected_page.dart';

class RoleGatePage extends StatelessWidget {
  const RoleGatePage({super.key});

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  bool _needsApproval(String role) =>
      role == 'chef' || role == 'student' || role == 'dietitian';

  String _norm(dynamic v, {String fallback = ''}) =>
      (v ?? fallback).toString().trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Kullanıcı bulunamadı")));
    }

    final docRef = _db.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Scaffold(body: Center(child: Text("Bir hata oluştu.")));
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data?.data();

        if (data == null) {
          return const _AllowedPage();
        }

        final role = _norm(data['role'], fallback: 'user');

        final fallbackStatus = _needsApproval(role) ? 'pending' : 'approved';
        final status = _norm(data['status'], fallback: fallbackStatus);

        if (_needsApproval(role)) {
          if (status == 'pending') return const WaitingApprovalPage();
          if (status == 'rejected') return const RejectedPage();
        }

        return const _AllowedPage();
      },
    );
  }
}

class _AllowedPage extends StatelessWidget {
  const _AllowedPage();

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
