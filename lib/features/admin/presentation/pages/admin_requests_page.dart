import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/features/admin/presentation/widgets/admin_users_list.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/welcome/welcome_page.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();

    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _pendingStream() {
    return FirebaseFirestore.instance
        .collection('users') // users koleksiyonuna gider
        .where(
          'status',
          isEqualTo: 'pending',
        ) // sadece bekleyen kullanıcıları çeker
        .snapshots(); // Firestore'daki değişiklikleri anlık yansıtır.
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _approvedStream() {
    return FirebaseFirestore.instance
        .collection('users') // users koleksiyonuna gider
        .where(
          'status',
          isEqualTo: 'approved',
        ) // sadece onaylanan kullanıcıları çeker
        .snapshots(); // veriyi anlık stream olarak dinler
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("Çıkış yapılamadı.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Paneli"),

        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Bekleyenler"),
            Tab(text: "Onaylananlar"),
          ],
        ),

        actions: [
          IconButton(
            onPressed: _logout, // çıkış fonksiyonunu çalıştırır
            icon: const Icon(Icons.logout),
            tooltip: "Çıkış",
          ),
        ],
      ),

      body: TabBarView(
        controller: _tab,
        children: [
          AdminUsersList(stream: _pendingStream(), mode: AdminListMode.pending),

          AdminUsersList(
            stream: _approvedStream(),
            mode: AdminListMode.approved,
          ),
        ],
      ),
    );
  }
}

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminRequestsPage();
  }
}
