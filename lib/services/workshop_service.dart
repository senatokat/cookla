import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_clock.dart';
import '../core/role_norm.dart';
import '../features/workshops/models/review.dart';
import '../features/workshops/models/workshop.dart';

class WorkshopService {
  WorkshopService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _workshops =>
      _db.collection('workshops');

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<JoinRequesterIdentity> getCurrentRequesterIdentity() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Oturum yok. Lutfen tekrar giris yap.');
    }

    final userDoc = await _users.doc(user.uid).get();
    final data = userDoc.data() ?? {};

    final composedName = [
      (data['name'] ?? '').toString().trim(),
      (data['surname'] ?? '').toString().trim(),
    ].where((part) => part.isNotEmpty).join(' ').trim();

    final fallbackName = (data['fullName'] ?? user.displayName ?? '')
        .toString()
        .trim();
    final userName = composedName.isNotEmpty ? composedName : fallbackName;
    final userEmail = (user.email ?? data['email'] ?? '').toString().trim();

    if (userName.length < 3) {
      throw Exception('Hesabindaki ad soyad bilgisi eksik.');
    }

    if (userEmail.isEmpty || !userEmail.contains('@')) {
      throw Exception('Hesabindaki e-posta bilgisi eksik.');
    }

    return JoinRequesterIdentity(name: userName, email: userEmail);
  }

  bool _isPast(DateTime date) => date.isBefore(AppClock.now());

  int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _parseDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<List<ChefOption>> listAvailableCoChefs() async {
    final currentUid = _auth.currentUser?.uid;
    final candidates = await _users.get();

    final options =
        candidates.docs
            .where((doc) {
              final data = doc.data();
              final role = AppRoles.normalize(data['role']);
              final status = (data['status'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              return doc.id != currentUid &&
                  (role == 'chef' || role == 'admin') &&
                  status == 'approved';
            })
            .map((doc) {
              final data = doc.data();
              final name = (data['name'] ?? '').toString().trim();
              final surname = (data['surname'] ?? '').toString().trim();
              final email = (data['email'] ?? '').toString().trim();
              final fullName = '$name $surname'.trim();
              return ChefOption(
                uid: doc.id,
                fullName: fullName.isEmpty ? email : fullName,
                email: email,
              );
            })
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return options;
  }

  Future<_ChefInvite?> _resolveCoChefInvite(
    String? chefId,
    String currentUid,
  ) async {
    final normalizedChefId = (chefId ?? '').trim();
    if (normalizedChefId.isEmpty) return null;
    if (normalizedChefId == currentUid) {
      throw Exception('İkinci şef olarak kendini seçemezsin.');
    }

    final doc = await _users.doc(normalizedChefId).get();
    if (!doc.exists) {
      throw Exception('Seçilen şef bulunamadı.');
    }

    final data = doc.data() ?? {};
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    final role = AppRoles.normalize(data['role']);
    if ((role != 'chef' && role != 'admin') || status != 'approved') {
      throw Exception('İkinci şef daveti için onaylı bir şef seçilmelidir.');
    }

    final fullName = [
      (data['name'] ?? '').toString().trim(),
      (data['surname'] ?? '').toString().trim(),
    ].where((part) => part.isNotEmpty).join(' ').trim();
    final candidateEmail = (data['email'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return _ChefInvite(
      uid: doc.id,
      name: fullName.isEmpty ? candidateEmail : fullName,
      email: candidateEmail,
    );
  }

  bool _isAcceptedCoChef(Map<String, dynamic>? data, String uid) {
    if (data == null) return false;
    final coChefId = (data['coChefId'] ?? '').toString().trim();
    final coChefStatus = (data['coChefStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return coChefId == uid && coChefStatus == 'accepted';
  }

  Stream<List<Workshop>> streamWorkshops() {
    return _workshops
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Workshop.fromDoc).toList());
  }

  Stream<List<Workshop>> streamPendingCoChefInvites() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<List<Workshop>>.empty();

    return _workshops
        .where('coChefId', isEqualTo: uid)
        .where('coChefStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(Workshop.fromDoc).toList());
  }

  Stream<Workshop> streamWorkshop(String workshopId) {
    return _workshops.doc(workshopId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception('Workshop bulunamadı.');
      }
      return Workshop.fromDoc(doc);
    });
  }

  Future<Workshop> getWorkshop(String workshopId) async {
    final doc = await _workshops.doc(workshopId).get();

    if (!doc.exists) {
      throw Exception('Workshop bulunamadı.');
    }

    return Workshop.fromDoc(doc);
  }

  Future<String> createWorkshop({
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String chefName,
    required int capacity,
    required int durationMinutes,
    required String recipeTitle,
    required String recipeIngredients,
    required String recipeSteps,
    String? coChefId,
  }) async {
    final currentUid = _auth.currentUser?.uid;

    if (currentUid == null) {
      throw Exception('Oturum bulunamadı.');
    }

    if (title.trim().isEmpty) {
      throw Exception('Baslik zorunludur.');
    }
    if (location.trim().isEmpty) {
      throw Exception('Konum zorunludur.');
    }
    if (chefName.trim().isEmpty) {
      throw Exception('Şef adı zorunludur.');
    }
    if (capacity <= 0) {
      throw Exception("Kontenjan 0'dan buyuk olmali.");
    }
    if (durationMinutes <= 0) {
      throw Exception("Tahmini süre 0'dan buyuk olmali.");
    }
    if (recipeTitle.trim().isEmpty) {
      throw Exception('Tarif adı zorunludur.');
    }
    if (recipeIngredients.trim().isEmpty) {
      throw Exception('Malzemeler zorunludur.');
    }
    if (recipeSteps.trim().isEmpty) {
      throw Exception('Yapilis zorunludur.');
    }
    if (_isPast(date)) {
      throw Exception('Geçmiş tarih için workshop oluşturulamaz.');
    }

    final endDate = date.add(Duration(minutes: durationMinutes));
    final coChefInvite = await _resolveCoChefInvite(coChefId, currentUid);

    final doc = await _workshops.add({
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'date': Timestamp.fromDate(date),
      'chefName': chefName.trim(),
      'capacity': capacity,
      'durationMinutes': durationMinutes,
      'endDate': Timestamp.fromDate(endDate),
      'attendees': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUid,
      'ratingAverage': 0.0,
      'ratingCount': 0,
      'recipe': {
        'title': recipeTitle.trim(),
        'ingredients': recipeIngredients.trim(),
        'steps': recipeSteps.trim(),
      },
      'coChefId': coChefInvite?.uid,
      'coChefName': coChefInvite?.name,
      'coChefEmail': coChefInvite?.email,
      'coChefStatus': coChefInvite == null ? null : 'pending',
    });

    return doc.id;
  }

  Future<void> acceptCoChefInvite(String workshopId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Oturum bulunamadı.');

    final ref = _workshops.doc(workshopId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Workshop bulunamadı.');

    final data = snap.data() ?? {};
    final coChefId = (data['coChefId'] ?? '').toString().trim();
    final coChefStatus = (data['coChefStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (coChefId != uid || coChefStatus != 'pending') {
      throw Exception('Bu daveti onaylama yetkin yok.');
    }

    await ref.update({
      'coChefStatus': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectCoChefInvite(String workshopId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Oturum bulunamadı.');

    final ref = _workshops.doc(workshopId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Workshop bulunamadı.');

    final data = snap.data() ?? {};
    final coChefId = (data['coChefId'] ?? '').toString().trim();
    final coChefStatus = (data['coChefStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (coChefId != uid || coChefStatus != 'pending') {
      throw Exception('Bu daveti reddetme yetkin yok.');
    }

    await ref.update({
      'coChefStatus': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteWorkshop(String workshopId) async {
    final canManage = await canManageRequests(workshopId);
    if (!canManage) {
      throw Exception('Silme yetkin yok.');
    }

    await _workshops.doc(workshopId).delete();
  }

  CollectionReference<Map<String, dynamic>> _reviews(String workshopId) {
    return _workshops.doc(workshopId).collection('reviews');
  }

  DocumentReference<Map<String, dynamic>> _reviewRef(
    String workshopId,
    String uid,
  ) {
    return _reviews(workshopId).doc(uid);
  }

  Stream<List<WorkshopReview>> streamReviews(String workshopId) {
    return _reviews(workshopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(WorkshopReview.fromDoc).toList());
  }

  Future<void> addOrUpdateReview({
    required String workshopId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Kullanıcı giris yapmamis.');
    }

    final workshopDoc = await _workshops.doc(workshopId).get();
    if (!workshopDoc.exists) {
      throw Exception('Workshop bulunamadı.');
    }

    final workshopData = workshopDoc.data() ?? {};
    final attendees = List<String>.from(workshopData['attendees'] ?? []);

    if (!attendees.contains(user.uid)) {
      throw Exception('Sadece etkinliğe katılan kullanıcılar yorum yapabilir.');
    }

    final endTs = workshopData['endDate'] as Timestamp?;
    if (endTs == null) {
      throw Exception('Workshop bitis zamani bulunamadı.');
    }

    if (AppClock.now().isBefore(endTs.toDate())) {
      throw Exception('Workshop bitmeden yorum yapamazsiniz.');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Puan 1 ile 5 arasinda olmalidir.');
    }

    if (comment.trim().isEmpty) {
      throw Exception('Yorum boş olamaz.');
    }

    final userDoc = await _users.doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final userName =
        (userData['name'] ??
                userData['fullName'] ??
                user.displayName ??
                'Kullanıcı')
            .toString();

    final reviewDocRef = _reviewRef(workshopId, user.uid);
    final workshopDocRef = _workshops.doc(workshopId);

    await _db.runTransaction((tx) async {
      final existingReviewSnap = await tx.get(reviewDocRef);
      final workshopSnap = await tx.get(workshopDocRef);

      if (!workshopSnap.exists) {
        throw Exception('Workshop bulunamadı.');
      }

      final data = workshopSnap.data() ?? {};

      final oldAverage = _parseDouble(data['ratingAverage']);
      final oldCount = _parseInt(data['ratingCount']);

      double newAverage = oldAverage;
      int newCount = oldCount;

      if (existingReviewSnap.exists) {
        final oldRating = _parseInt(existingReviewSnap.data()?['rating']);
        final total = (oldAverage * oldCount) - oldRating + rating;
        newAverage = oldCount == 0 ? 0 : total / oldCount;
      } else {
        final total = (oldAverage * oldCount) + rating;
        newCount = oldCount + 1;
        newAverage = newCount == 0 ? 0 : total / newCount;
      }

      tx.set(reviewDocRef, {
        'userId': user.uid,
        'userName': userName,
        'rating': rating,
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.update(workshopDocRef, {
        'ratingAverage': double.parse(newAverage.toStringAsFixed(1)),
        'ratingCount': newCount,
      });
    });
  }

  Future<void> deleteMyReview({required String workshopId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı giris yapmamis.');
    }

    final workshopDocRef = _workshops.doc(workshopId);
    final reviewDocRef = _reviewRef(workshopId, user.uid);

    await _db.runTransaction((tx) async {
      final reviewSnap = await tx.get(reviewDocRef);
      if (!reviewSnap.exists) return;

      final workshopSnap = await tx.get(workshopDocRef);
      if (!workshopSnap.exists) {
        throw Exception('Workshop bulunamadı.');
      }

      final workshopData = workshopSnap.data() ?? {};
      final reviewData = reviewSnap.data() ?? {};

      final oldAverage = _parseDouble(workshopData['ratingAverage']);
      final oldCount = _parseInt(workshopData['ratingCount']);
      final oldRating = _parseInt(reviewData['rating']);

      final newCount = oldCount > 0 ? oldCount - 1 : 0;

      double newAverage = 0;
      if (newCount > 0) {
        final total = (oldAverage * oldCount) - oldRating;
        newAverage = total / newCount;
      }

      tx.delete(reviewDocRef);
      tx.update(workshopDocRef, {
        'ratingAverage': double.parse(newAverage.toStringAsFixed(1)),
        'ratingCount': newCount,
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _reqRef(
    String workshopId,
    String uid,
  ) {
    return _workshops.doc(workshopId).collection('requests').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _reqs(String workshopId) {
    return _workshops.doc(workshopId).collection('requests');
  }

  Stream<JoinRequest?> streamMyRequest(String workshopId) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Stream<JoinRequest?>.value(null);
    }

    return _reqRef(workshopId, uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() ?? {};
      return JoinRequest.fromMap(doc.id, data);
    });
  }

  Stream<int> streamApprovedCount(String workshopId) {
    return _reqs(workshopId)
        .where('status', isEqualTo: RequestStatus.approved)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<int> getApprovedCount(String workshopId) async {
    final snap = await _reqs(
      workshopId,
    ).where('status', isEqualTo: RequestStatus.approved).get();

    return snap.docs.length;
  }

  Future<void> requestJoin({
    required String workshopId,
    required String userName,
    required String userEmail,
  }) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception('Oturum yok. Lutfen tekrar giris yap.');
    }
    if (userName.trim().isEmpty) {
      throw Exception('Ad soyad zorunludur.');
    }
    if (userEmail.trim().isEmpty) {
      throw Exception('E-posta zorunludur.');
    }

    final workshop = await getWorkshop(workshopId);

    if (_isPast(workshop.date)) {
      throw Exception('Geçmiş etkinliğe katılım isteği gönderilemez.');
    }

    final approvedCount = await getApprovedCount(workshopId);
    if (approvedCount >= workshop.capacity) {
      throw Exception('Workshop kontenjani dolu.');
    }

    final existing = await _reqRef(workshopId, uid).get();
    if (existing.exists) {
      final status = (existing.data()?['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (status == RequestStatus.approved) {
        throw Exception('Zaten katiliyorsun.');
      }
      if (status == RequestStatus.pending) {
        throw Exception('Zaten bekleyen isteğin var.');
      }
    }

    await _reqRef(workshopId, uid).set({
      'uid': uid,
      'workshopId': workshopId,
      'userName': userName.trim(),
      'userEmail': userEmail.trim(),
      'status': RequestStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<JoinRequest>> streamRequests(String workshopId) {
    return _reqs(workshopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => JoinRequest.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<String?> getMyRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;

    return AppRoles.normalize(doc.data()?['role']);
  }

  Future<bool> canManageRequests(String workshopId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final role = await getMyRole();

    if (AppRoles.isAdmin(role)) return true;

    if (AppRoles.isChef(role)) {
      final doc = await _workshops.doc(workshopId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final createdBy = (data?['createdBy'] ?? '').toString().trim();
      return createdBy == uid || _isAcceptedCoChef(data, uid);
    }

    return false;
  }

  Future<void> approveRequest({
    required String workshopId,
    required String uid,
  }) async {
    final canManage = await canManageRequests(workshopId);
    if (!canManage) {
      throw Exception('Bu isteği onaylama yetkin yok.');
    }

    final workshop = await getWorkshop(workshopId);
    if (_isPast(workshop.date)) {
      throw Exception('Geçmiş etkinlik için katılım isteği onaylanamaz.');
    }

    final workshopDocRef = _workshops.doc(workshopId);
    final reqDocRef = _reqRef(workshopId, uid);

    await _db.runTransaction((tx) async {
      final reqDoc = await tx.get(reqDocRef);
      final workshopSnap = await tx.get(workshopDocRef);

      if (!reqDoc.exists) {
        throw Exception('Katılım isteği bulunamadı.');
      }

      if (!workshopSnap.exists) {
        throw Exception('Workshop bulunamadı.');
      }

      final workshopData = workshopSnap.data() ?? {};
      final reqData = reqDoc.data() ?? {};

      final dateTs = workshopData['date'] as Timestamp?;
      if (dateTs == null) {
        throw Exception('Workshop tarihi bulunamadı.');
      }

      if (_isPast(dateTs.toDate())) {
        throw Exception('Geçmiş etkinlik için katılım isteği onaylanamaz.');
      }

      final currentStatus = (reqData['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      final attendees = List<String>.from(workshopData['attendees'] ?? []);

      if (currentStatus != RequestStatus.approved &&
          attendees.length >= workshop.capacity) {
        throw Exception('Kontenjan dolu.');
      }

      tx.set(reqDocRef, {
        'status': RequestStatus.approved,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!attendees.contains(uid)) {
        attendees.add(uid);
        tx.update(workshopDocRef, {'attendees': attendees});
      }
    });
  }

  Future<void> rejectRequest({
    required String workshopId,
    required String uid,
  }) async {
    final canManage = await canManageRequests(workshopId);
    if (!canManage) {
      throw Exception('Bu isteği reddetme yetkin yok.');
    }

    final workshop = await getWorkshop(workshopId);
    if (_isPast(workshop.date)) {
      throw Exception('Geçmiş etkinlik için katılım isteği güncellenemez.');
    }

    final workshopDocRef = _workshops.doc(workshopId);
    final reqDocRef = _reqRef(workshopId, uid);

    await _db.runTransaction((tx) async {
      final workshopSnap = await tx.get(workshopDocRef);
      final reqSnap = await tx.get(reqDocRef);

      if (!workshopSnap.exists) {
        throw Exception('Workshop bulunamadı.');
      }

      if (!reqSnap.exists) {
        throw Exception('Katılım isteği bulunamadı.');
      }

      final workshopData = workshopSnap.data() ?? {};
      final attendees = List<String>.from(workshopData['attendees'] ?? []);

      attendees.remove(uid);

      tx.set(reqDocRef, {
        'status': RequestStatus.rejected,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.update(workshopDocRef, {'attendees': attendees});
    });
  }
}

class RequestStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
}

class JoinRequesterIdentity {
  final String name;
  final String email;

  const JoinRequesterIdentity({required this.name, required this.email});
}

class JoinRequest {
  final String id;
  final String status;
  final String userName;
  final String userEmail;
  final String attendanceStatus;

  const JoinRequest({
    required this.id,
    required this.status,
    required this.userName,
    required this.userEmail,
    required this.attendanceStatus,
  });

  factory JoinRequest.fromMap(String id, Map<String, dynamic> data) {
    return JoinRequest(
      id: id,
      status: (data['status'] ?? RequestStatus.pending)
          .toString()
          .trim()
          .toLowerCase(),
      userName: (data['userName'] ?? '').toString(),
      userEmail: (data['userEmail'] ?? '').toString(),
      attendanceStatus: (data['attendanceStatus'] ?? 'pending')
          .toString()
          .trim()
          .toLowerCase(),
    );
  }
}

class ChefOption {
  final String uid;
  final String fullName;
  final String email;

  const ChefOption({
    required this.uid,
    required this.fullName,
    required this.email,
  });
}

class _ChefInvite {
  final String uid;
  final String name;
  final String email;

  const _ChefInvite({
    required this.uid,
    required this.name,
    required this.email,
  });
}
