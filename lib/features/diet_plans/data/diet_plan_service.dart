import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/core/app_clock.dart';
import 'package:flutter_application_1/core/roles.dart';
import 'package:flutter_application_1/core/text_formatters.dart';
import 'package:flutter_application_1/features/diet_plans/models/weekly_diet_plan.dart';
import 'package:flutter_application_1/features/recipes/models/recipe.dart';

class DietPlanService {
  DietPlanService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _plans =>
      _db.collection('weeklyDietPlans');

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  String? get currentUid => _auth.currentUser?.uid;

  Future<User> _requireUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı bulunamadı');
    return user;
  }

  Future<Map<String, dynamic>> _getMyUserData(User user) async {
    final doc = await _users.doc(user.uid).get();
    return doc.data() ?? {};
  }

  Future<Map<String, dynamic>> _requireApprovedDietitian(User user) async {
    final data = await _getMyUserData(user);
    final role = AppRoles.normalize(data['role'], fallback: AppRoles.user);
    final status = AppUserStatus.normalize(
      data['status'],
      fallback: AppUserStatus.pending,
    );

    if (role != AppRoles.dietitian || status != AppUserStatus.approved) {
      throw Exception('Bu işlem için onaylı diyetisyen hesabı gerekir.');
    }

    return data;
  }

  Stream<List<WeeklyDietPlan>> streamMyPlans() {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) return const Stream.empty();

    return _plans.where('dietitianId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => WeeklyDietPlan.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<WeeklyDietPlan>> streamPublishedPlans() {
    return _plans.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => WeeklyDietPlan.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<WeeklyDietPlan>> streamSavedPlans() {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) return const Stream.empty();

    return _plans.where('savedBy', arrayContains: uid).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => WeeklyDietPlan.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<WeeklyDietPlan?> streamPlan(String planId) {
    if (planId.trim().isEmpty) return Stream.value(null);

    return _plans.doc(planId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return WeeklyDietPlan.fromMap(doc.id, data);
    });
  }

  Stream<WeeklyDietPlan?> streamActivePlan(String uid) {
    if (uid.trim().isEmpty) return Stream.value(null);

    return _users.doc(uid).snapshots().asyncMap((userDoc) async {
      final planId = (userDoc.data()?['activeDietPlanId'] ?? '')
          .toString()
          .trim();
      if (planId.isEmpty) return null;

      final planDoc = await _plans.doc(planId).get();
      final data = planDoc.data();
      if (data == null) return null;

      return WeeklyDietPlan.fromMap(planDoc.id, data);
    });
  }

  Future<void> startPlan(WeeklyDietPlan plan) async {
    final user = await _requireUser();

    await _users.doc(user.uid).set({
      'activeDietPlanId': plan.id,
      'activeDietPlanTitle': plan.title,
      'activeDietPlanDietitianName': plan.dietitianName,
      'activeDietPlanStartedAt': AppClock.timestampNow(),
    }, SetOptions(merge: true));
  }

  Future<void> finishActivePlan() async {
    final user = await _requireUser();

    await _users.doc(user.uid).set({
      'activeDietPlanId': FieldValue.delete(),
      'activeDietPlanTitle': FieldValue.delete(),
      'activeDietPlanDietitianName': FieldValue.delete(),
      'activeDietPlanStartedAt': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleSavePlan(String planId) async {
    final user = await _requireUser();
    final ref = _plans.doc(planId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw Exception('Program bulunamadı.');

    final savedBy = List<String>.from(data['savedBy'] ?? const <String>[]);
    final alreadySaved = savedBy.contains(user.uid);

    await ref.update({
      'savedBy': alreadySaved
          ? FieldValue.arrayRemove([user.uid])
          : FieldValue.arrayUnion([user.uid]),
    });
  }

  Stream<List<WeeklyDietPlan>> streamPlansByDietitian(String dietitianId) {
    if (dietitianId.trim().isEmpty) return const Stream.empty();

    return _plans.where('dietitianId', isEqualTo: dietitianId).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => WeeklyDietPlan.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> createWeeklyPlan({
    required String title,
    required String notes,
    required List<DietPlanDay> days,
  }) async {
    final user = await _requireUser();
    final userData = await _requireApprovedDietitian(user);
    final cleanedTitle = title.trim();
    final cleanedNotes = notes.trim();

    if (cleanedTitle.isEmpty) {
      throw Exception('Program basligi zorunlu.');
    }

    final normalizedDays = await _validateAndNormalizeDays(days);
    final hasAnyItem = normalizedDays.any((day) => day.hasAnyItem);
    if (!hasAnyItem) {
      throw Exception('En az bir tarif veya ara ogun eklemelisin.');
    }

    final dietitianName = AppTextFormatters.displayName([
      (userData['name'] ?? '').toString().trim(),
      (userData['surname'] ?? '').toString().trim(),
    ]);

    await _plans.add({
      'title': cleanedTitle,
      'notes': cleanedNotes,
      'dietitianId': user.uid,
      'dietitianName': dietitianName.isEmpty ? 'Diyetisyen' : dietitianName,
      'isPublished': true,
      'createdAt': AppClock.timestampNow(),
      'updatedAt': AppClock.timestampNow(),
      'savedBy': <String>[],
      'days': normalizedDays.map((day) => day.toMap()).toList(),
    });
  }

  Future<void> deletePlan(String planId) async {
    final user = await _requireUser();
    final doc = await _plans.doc(planId).get();
    final data = doc.data();
    if (data == null) throw Exception('Program bulunamadı.');

    final ownerId = (data['dietitianId'] ?? '').toString();
    if (ownerId != user.uid) {
      throw Exception('Bu programı silme yetkin yok.');
    }

    await _plans.doc(planId).delete();
  }

  Future<List<DietPlanDay>> _validateAndNormalizeDays(
    List<DietPlanDay> days,
  ) async {
    final normalized = <DietPlanDay>[];

    for (final day in days) {
      normalized.add(
        DietPlanDay(
          dayIndex: day.dayIndex,
          dayName: day.dayName,
          breakfast: await _validatedMeal(day.breakfast),
          lunch: await _validatedMeal(day.lunch),
          dinner: await _validatedMeal(day.dinner),
          snacks: _cleanSnacks(day.snacks),
        ),
      );
    }

    return normalized;
  }

  Future<DietPlanMeal?> _validatedMeal(DietPlanMeal? meal) async {
    if (meal == null || meal.recipeId.trim().isEmpty) return null;

    final doc = await _recipes.doc(meal.recipeId).get();
    final data = doc.data();
    if (data == null) throw Exception('Seçilen tarif bulunamadı.');

    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    final authorRole = (data['authorRole'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (status != 'approved' || authorRole != AppRoles.chef) {
      throw Exception(
        'Programda sadece yayındaki şef tarifleri kullanilabilir.',
      );
    }

    return DietPlanMeal.fromRecipe(Recipe.fromMap(doc.id, data));
  }

  List<String> _cleanSnacks(List<String> snacks) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final item in snacks) {
      final text = item.trim();
      if (text.isEmpty) continue;
      final key = text.toLowerCase();
      if (seen.add(key)) cleaned.add(text);
    }

    return cleaned.take(2).toList();
  }
}
