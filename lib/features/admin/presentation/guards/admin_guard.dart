import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/services/admin_service.dart';

class AdminGuard extends StatefulWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  Future<bool>? _future;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      _future = AdminService().isAdmin(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const _NotAllowed(msg: "Oturum bulunamadı.");
    }

    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return _NotAllowed(msg: "Hata: ${snap.error}");
        }

        final isAdmin = snap.data == true;

        if (!isAdmin) {
          return const _NotAllowed(msg: "Bu sayfaya erişim yetkiniz yok.");
        }

        return widget.child;
      },
    );
  }
}

class _NotAllowed extends StatelessWidget {
  final String msg;

  const _NotAllowed({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Erişim Yok")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(msg, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
