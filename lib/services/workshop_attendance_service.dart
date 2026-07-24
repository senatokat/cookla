import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/role_norm.dart';

class WorkshopAttendanceService {
  WorkshopAttendanceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _workshops =>
      _db.collection('workshops');

  DocumentReference<Map<String, dynamic>> _reqRef(
    String workshopId,
    String uid,
  ) {
    return _workshops.doc(workshopId).collection('requests').doc(uid);
  }

  Future<String?> getMyRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'];
  }

  Future<bool> canMarkAttendance(String workshopId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final role = await getMyRole();
    if (!AppRoles.isChef(role)) return false;

    final doc = await _workshops.doc(workshopId).get();
    if (!doc.exists) return false;

    final data = doc.data() ?? {};
    final createdBy = (data['createdBy'] ?? '').toString().trim();
    final coChefId = (data['coChefId'] ?? '').toString().trim();
    final coChefStatus = (data['coChefStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return createdBy == uid || (coChefId == uid && coChefStatus == 'accepted');
  }

  Future<void> markAttendance({
    required String workshopId,
    required String uid,
    required String status,
  }) async {
    final allowed = await canMarkAttendance(workshopId);

    if (!allowed) {
      throw Exception('Bu işlem için yetkin yok.');
    }

    if (status != 'attended' && status != 'absent') {
      throw Exception('Gecersiz durum.');
    }

    final ref = _reqRef(workshopId, uid);
    final snap = await ref.get();

    if (!snap.exists) {
      throw Exception('Kullanıcı bulunamadı.');
    }

    final data = snap.data() ?? {};
    final reqStatus = (data['status'] ?? '').toString();

    if (reqStatus != 'approved') {
      throw Exception('Sadece onaylı kullanıcı isaretlenebilir.');
    }

    await ref.set({
      'attendanceStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
