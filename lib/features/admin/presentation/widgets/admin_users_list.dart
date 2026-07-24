import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/roles.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/user_card.dart';

import 'package:flutter_application_1/shared/widgets/empty_state.dart';

enum AdminListMode { pending, approved }

class AdminUsersList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final AdminListMode mode;

  const AdminUsersList({super.key, required this.stream, required this.mode});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Hata: ${snap.error}", textAlign: TextAlign.center),
            ),
          );
        }
        final rawDocs = snap.data?.docs ?? [];

        final docs = rawDocs.where((d) {
          final data = d.data();
          final status = (data['status'] ?? 'pending')
              .toString()
              .trim()
              .toLowerCase();
          final role = AppRoles.normalize(
            data['role'],
            fallback: AppRoles.user,
          );
          final needsApproval = AppRoles.needsApproval(role);

          if (mode == AdminListMode.pending) {
            return status == AppUserStatus.pending && needsApproval;
          }
          if (mode == AdminListMode.approved) {
            return status == AppUserStatus.approved && needsApproval;
          }

          return true;
        }).toList();

        if (docs.isEmpty) {
          return const EmptyState(
            title: "Liste boş",
            subtitle: "Şu anda gösterilecek kullanıcı yok.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return UserCard(uid: doc.id, data: doc.data(), mode: mode);
          },
        );
      },
    );
  }
}
