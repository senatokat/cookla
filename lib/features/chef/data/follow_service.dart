import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final _db = FirebaseFirestore.instance;

  final _auth = FirebaseAuth.instance;

  String? get _myUid => _auth.currentUser?.uid;

  Future<void> follow(String targetUid) async {
    final me = _myUid;

    if (me == null || me == targetUid) return;

    final batch = _db.batch();

    final myDoc = _db.collection('users').doc(me);

    final targetDoc = _db.collection('users').doc(targetUid);

    final followingRef = myDoc.collection('following').doc(targetUid);

    final followerRef = targetDoc.collection('followers').doc(me);

    batch.set(followingRef, {'createdAt': FieldValue.serverTimestamp()});

    batch.set(followerRef, {'createdAt': FieldValue.serverTimestamp()});

    batch.set(myDoc, {
      'followingCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    batch.set(targetDoc, {
      'followersCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> unfollow(String targetUid) async {
    final me = _myUid;

    if (me == null || me == targetUid) return;

    final batch = _db.batch();

    final myDoc = _db.collection('users').doc(me);
    final targetDoc = _db.collection('users').doc(targetUid);

    final followingRef = myDoc.collection('following').doc(targetUid);
    final followerRef = targetDoc.collection('followers').doc(me);

    batch.delete(followingRef);

    batch.delete(followerRef);

    batch.set(myDoc, {
      'followingCount': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    batch.set(targetDoc, {
      'followersCount': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<bool> isFollowing(String targetUid) {
    final me = _myUid;

    if (me == null) return Stream.value(false);

    return _db
        .collection('users')
        .doc(me)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
