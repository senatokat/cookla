import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/roles.dart';

class UserRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> upsertUser({
    required String uid,
    required String email,
    required String name,
    required String surname,
    required String role,
  }) async {
    final normalizedRole = AppRoles.normalize(role);

    final status = (normalizedRole == AppRoles.admin)
        ? AppUserStatus.approved
        : (AppRoles.needsApproval(normalizedRole)
              ? AppUserStatus.pending
              : AppUserStatus.approved);

    await _db.collection("users").doc(uid).set({
      "uid": uid,
      "email": email,
      "name": name,
      "surname": surname,
      "role": normalizedRole,
      "status": status,
      "onboardingDone": false,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingAll() {
    return _db
        .collection("users")
        .where("status", isEqualTo: "pending")
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchApprovedAll() {
    return _db
        .collection("users")
        .where("status", isEqualTo: "approved")
        .snapshots();
  }

  Future<void> setStatus({
    required String uid,
    required String status, // pending / approved / rejected
    String? reviewedBy,
  }) async {
    final now = FieldValue.serverTimestamp();

    final payload = <String, dynamic>{
      "status": status,
      "updatedAt": now,
      "reviewedBy": reviewedBy,
      "reviewedAt": now,
    };

    if (status == "approved") {
      payload["approvedAt"] = now;
      payload["approvedBy"] = reviewedBy;
      payload["rejectedAt"] = FieldValue.delete();
      payload["rejectedBy"] = FieldValue.delete();
    }

    if (status == "rejected") {
      payload["rejectedAt"] = now;
      payload["rejectedBy"] = reviewedBy;
      payload["approvedAt"] = FieldValue.delete();
      payload["approvedBy"] = FieldValue.delete();
    }

    if (status == "pending") {
      payload["approvedAt"] = FieldValue.delete();
      payload["approvedBy"] = FieldValue.delete();
      payload["rejectedAt"] = FieldValue.delete();
      payload["rejectedBy"] = FieldValue.delete();
    }

    await _db
        .collection("users")
        .doc(uid)
        .set(payload, SetOptions(merge: true));
  }
}
