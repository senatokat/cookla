import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final _db = FirebaseFirestore.instance;

  Future<bool> isAdmin(String uid) async {
    final doc = await _db.collection('admins').doc(uid).get();
    return doc.exists;
  }
}
