import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/core/roles.dart';

class RoleService {
  RoleService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  String _statusFallbackForRole(String role) {
    return AppRoles.needsApproval(role)
        ? AppUserStatus.pending
        : AppUserStatus.approved;
  }

  Future<RoleInfo> getRoleInfo(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();

      final role = AppRoles.normalize(data?['role'], fallback: AppRoles.user);
      final status = AppUserStatus.normalize(
        data?['status'],
        fallback: _statusFallbackForRole(role),
      );

      return RoleInfo(role: role, status: status);
    } catch (_) {
      return const RoleInfo(role: AppRoles.user, status: AppUserStatus.pending);
    }
  }

  Future<RoleInfo> getMyRoleInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const RoleInfo(role: AppRoles.user, status: AppUserStatus.pending);
    }
    return getRoleInfo(uid);
  }

  Future<bool> isAdmin(String uid) async {
    final info = await getRoleInfo(uid);
    return info.isAdmin;
  }

  Future<bool> canManageWorkshops(String uid) async {
    final info = await getRoleInfo(uid);
    return info.canManageWorkshops;
  }

  Future<bool> isCurrentUserAdmin() async {
    final info = await getMyRoleInfo();
    return info.isAdmin;
  }

  Future<bool> canCurrentUserManageWorkshops() async {
    final info = await getMyRoleInfo();
    return info.canManageWorkshops;
  }

  Stream<RoleInfo> watchRoleInfo(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      final role = AppRoles.normalize(data?['role'], fallback: AppRoles.user);
      final status = AppUserStatus.normalize(
        data?['status'],
        fallback: _statusFallbackForRole(role),
      );
      return RoleInfo(role: role, status: status);
    });
  }

  Stream<RoleInfo> watchMyRoleInfo() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(
        const RoleInfo(role: AppRoles.user, status: AppUserStatus.pending),
      );
    }
    return watchRoleInfo(uid);
  }
}
