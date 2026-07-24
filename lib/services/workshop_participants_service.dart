import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/role_norm.dart';
import '../features/workshops/models/workshop_attendee.dart';

class WorkshopParticipantsService {
  WorkshopParticipantsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _workshops =>
      _db.collection('workshops');

  CollectionReference<Map<String, dynamic>> _requests(String workshopId) {
    return _workshops.doc(workshopId).collection('requests');
  }

  DocumentReference<Map<String, dynamic>> _requestRef(
    String workshopId,
    String uid,
  ) {
    return _requests(workshopId).doc(uid);
  }

  Future<String?> _getMyRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return AppRoles.normalize(doc.data()?['role']);
  }

  Future<bool> canMarkAttendance(String workshopId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final role = await _getMyRole();
    if (!AppRoles.isChef(role)) return false;

    final workshopDoc = await _workshops.doc(workshopId).get();
    if (!workshopDoc.exists) return false;

    final data = workshopDoc.data() ?? {};
    final createdBy = (data['createdBy'] ?? '').toString().trim();
    final coChefId = (data['coChefId'] ?? '').toString().trim();
    final coChefStatus = (data['coChefStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return createdBy == uid || (coChefId == uid && coChefStatus == 'accepted');
  }

  Stream<List<WorkshopAttendee>> streamApprovedParticipants(String workshopId) {
    return _requests(
      workshopId,
    ).where('status', isEqualTo: 'approved').snapshots().map((snap) {
      final docs = [...snap.docs];

      docs.sort((a, b) {
        final aTs = a.data()['createdAt'] as Timestamp?;
        final bTs = b.data()['createdAt'] as Timestamp?;
        final aValue = aTs?.millisecondsSinceEpoch ?? 0;
        final bValue = bTs?.millisecondsSinceEpoch ?? 0;
        return aValue.compareTo(bValue);
      });

      return docs
          .map((doc) => WorkshopAttendee.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> markAttendance({
    required String workshopId,
    required String uid,
    required String attendanceStatus,
  }) async {
    final allowed = await canMarkAttendance(workshopId);
    if (!allowed) {
      throw Exception('Bu işlem için yetkin yok.');
    }

    if (attendanceStatus != 'attended' && attendanceStatus != 'absent') {
      throw Exception('Gecersiz katılım durumu.');
    }

    final ref = _requestRef(workshopId, uid);
    final snap = await ref.get();

    if (!snap.exists) {
      throw Exception('Katılımci bulunamadı.');
    }

    final data = snap.data() ?? {};
    final requestStatus = (data['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (requestStatus != 'approved') {
      throw Exception('Sadece onaylı katılımcilar isaretlenebilir.');
    }

    await ref.set({
      'attendanceStatus': attendanceStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
