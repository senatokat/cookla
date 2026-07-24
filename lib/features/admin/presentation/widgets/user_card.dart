import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/features/admin/presentation/widgets/badge_widget.dart';
import 'package:flutter_application_1/features/admin/presentation/widgets/admin_users_list.dart';

class UserCard extends StatelessWidget {
  final String uid;

  final Map<String, dynamic> data;

  final AdminListMode mode;

  const UserCard({
    super.key,
    required this.uid,
    required this.data,
    required this.mode,
  });

  String _roleText(String? role) {
    final r = (role ?? "").trim().toLowerCase();
    switch (r) {
      case "student":
        return "Gastronomi Öğrencisi";
      case "chef":
        return "Profesyonel Şef";
      case "gastrochef":
        return "Gastronomi Şefi";
      case "dietitian":
        return "Diyetisyen";
      case "admin":
        return "Admin";
      case "user":
        return "Genel Kullanıcı";
      default:
        return r.isEmpty ? "Bilinmiyor" : r; // boşsa fallback
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange; // pending
    }
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    final now = FieldValue.serverTimestamp(); // sunucu zamanı
    final adminUid =
        FirebaseAuth.instance.currentUser?.uid; // işlemi yapan admin

    final payload = <String, dynamic>{
      "status": newStatus, // pending / approved / rejected
      "updatedAt": now,
      "reviewedBy": adminUid,
      "reviewedAt": now,
    };

    if (newStatus == "approved") {
      payload["approvedAt"] = now;
      payload["approvedBy"] = adminUid;

      payload["rejectedAt"] = FieldValue.delete();
      payload["rejectedBy"] = FieldValue.delete();
    } else if (newStatus == "rejected") {
      payload["rejectedAt"] = now;
      payload["rejectedBy"] = adminUid;

      payload["approvedAt"] = FieldValue.delete();
      payload["approvedBy"] = FieldValue.delete();
    } else if (newStatus == "pending") {
      payload["approvedAt"] = FieldValue.delete();
      payload["approvedBy"] = FieldValue.delete();
      payload["rejectedAt"] = FieldValue.delete();
      payload["rejectedBy"] = FieldValue.delete();
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(payload, SetOptions(merge: true));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("Güncellendi")));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = (data["email"] ?? "email yok").toString();

    final role = data["role"]?.toString();

    final status = (data["status"] ?? "pending")
        .toString()
        .trim()
        .toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BadgeWidget(text: _roleText(role)),
              BadgeWidget(text: "Durum: $status", color: _statusColor(status)),
            ],
          ),

          const SizedBox(height: 12),

          if (mode == AdminListMode.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, "rejected"),
                    child: const Text("Reddet"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, "approved"),
                    child: const Text("Onayla"),
                  ),
                ),
              ],
            ),

          if (mode == AdminListMode.approved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateStatus(context, "pending"),
                child: const Text("Onayı Geri Al"),
              ),
            ),
        ],
      ),
    );
  }
}
