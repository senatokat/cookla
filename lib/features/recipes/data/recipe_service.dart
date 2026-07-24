import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/core/app_clock.dart';
import 'package:flutter_application_1/core/text_formatters.dart';
import '../models/recipe.dart';

class RecipeService {
  RecipeService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  String _normalizeRole(dynamic value) {
    return (value ?? '').toString().trim().toLowerCase();
  }

  Future<User> _requireUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı bulunamadı');
    }
    return user;
  }

  Future<Map<String, dynamic>> _getMyUserData() async {
    final user = await _requireUser();
    final doc = await _users.doc(user.uid).get();
    return doc.data() ?? {};
  }

  Future<String?> getMyRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _users.doc(user.uid).get();
    final data = doc.data();

    return _normalizeRole(data?['role']);
  }

  String? get currentUid => _auth.currentUser?.uid;

  Future<bool> canManageRecipes() async {
    final role = await getMyRole();
    return role == 'chef' || role == 'admin';
  }

  Future<bool> canGiveDietitianApproval() async {
    final data = await _getMyUserData();
    final role = _normalizeRole(data['role']);
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    return (role == 'dietitian' || role == 'admin') && status == 'approved';
  }

  Future<void> _ensureCanManageRecipes() async {
    final ok = await canManageRecipes();
    if (!ok) {
      throw Exception('Bu işlem için yetkin yok');
    }
  }

  Future<String> createRecipe({
    required String title,
    required String description,
    required List<String> ingredientNames,
    required String steps,
    Map<String, String> ingredientAmounts = const <String, String>{},
    String? imageUrl,
    int? durationMinutes,
    String? difficulty,
  }) async {
    final user = await _requireUser();
    final userData = await _getMyUserData();
    final authorName = AppTextFormatters.displayName([
      (userData['name'] ?? '').toString().trim(),
      (userData['surname'] ?? '').toString().trim(),
    ]);
    final authorRole = _normalizeRole(userData['role']).isEmpty
        ? 'user'
        : _normalizeRole(userData['role']);
    final publishDirectly =
        authorRole == 'chef' ||
        authorRole == 'admin' ||
        authorRole == 'dietitian';
    final initialStatus = publishDirectly ? 'approved' : 'pending';

    await _recipes.add({
      'title': title.trim(),
      'description': description.trim(),
      'ingredients': ingredientNames.join('\n').trim(),
      'ingredientsList': ingredientNames
          .map(
            (item) => RecipeIngredient.fromName(
              item,
              amount: ingredientAmounts[item] ?? '',
            ).toMap(),
          )
          .toList(),
      'steps': steps.trim(),
      'authorId': user.uid,
      'authorName': authorName.isEmpty ? 'Kullanıcı' : authorName,
      'authorRole': authorRole,
      'status': initialStatus,
      'createdAt': FieldValue.serverTimestamp(),
      'approvedAt': publishDirectly ? FieldValue.serverTimestamp() : null,
      'approvedBy': publishDirectly ? user.uid : null,
      'dietitianApproved': false,
      'dietitianApprovedAt': null,
      'dietitianApprovedBy': null,
      'dietitianApprovedByName': null,
      'imageUrl': (imageUrl == null || imageUrl.trim().isEmpty)
          ? null
          : imageUrl.trim(),
      'durationMinutes': durationMinutes,
      'difficulty': (difficulty == null || difficulty.trim().isEmpty)
          ? null
          : difficulty.trim(),
      'ratingAverage': 0,
      'ratingCount': 0,
      'likedBy': <String>[],
      'savedBy': <String>[],
    });

    return initialStatus;
  }

  Future<int> seedDefaultRecipesIfEmpty() async {
    final approverUid = _auth.currentUser?.uid ?? 'system';
    final now = AppClock.now();
    // Aynı başlıktaki tarifleri tekrar eklemeyerek seed işlemini güvenli tutuyoruz.
    final defaults = [
      {
        'title': 'Domatesli Makarna',
        'description': 'Pratik, doyurucu ve her mutfağa uygun klasik makarna.',
        'ingredientNames': [
          'Makarna',
          'Domates',
          'Salça',
          'Soğan',
          'Sarımsak',
          'Zeytinyağı',
          'Tuz',
          'Karabiber',
        ],
        'steps':
            'Makarnayı haşla.\nSoğan ve sarımsağı kavur.\nSalça ve domatesi ekle.\nMakarna ile birleştirip servis et.',
        'imageUrl':
            'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=1200',
        'durationMinutes': 25,
        'difficulty': 'Kolay',
      },
      {
        'title': 'Sebzeli Omlet',
        'description':
            'Yumurta ve sebzeleri bir araya getiren hızlı kahvaltı tarifi.',
        'ingredientNames': [
          'Yumurta',
          'Biber',
          'Domates',
          'Peynir',
          'Maydanoz',
          'Tereyağı',
          'Tuz',
        ],
        'steps':
            'Sebzeleri doğra.\nTereyağında sebzeleri çevir.\nÇırpılmış yumurtayı ekle.\nPeynir ile tamamla.',
        'imageUrl':
            'https://images.unsplash.com/photo-1510693206972-df098062cb71?w=1200',
        'durationMinutes': 15,
        'difficulty': 'Kolay',
      },
      {
        'title': 'Fırında Tavuk Patates',
        'description': 'Akşam yemeği için zahmetsiz ve doyurucu fırın tarifi.',
        'ingredientNames': [
          'Tavuk',
          'Patates',
          'Soğan',
          'Zeytinyağı',
          'Kekik',
          'Karabiber',
          'Tuz',
        ],
        'steps':
            'Tavuk ve patatesi doğra.\nBaharat ve yağ ile harmanla.\nFırında kızarana kadar pişir.',
        'imageUrl':
            'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=1200',
        'durationMinutes': 55,
        'difficulty': 'Orta',
      },
      {
        'title': 'Mercimek Çorbası',
        'description': 'Az malzemeyle hazırlanan sıcak ve besleyici çorba.',
        'ingredientNames': [
          'Mercimek',
          'Soğan',
          'Havuç',
          'Patates',
          'Zeytinyağı',
          'Tuz',
          'Kimyon',
        ],
        'steps':
            'Soğanı zeytinyağında çevir.\nHavuç, patates ve mercimeği ekle.\nÜzerini geçecek kadar su koyup pişir.\nBlenderdan geçirip baharatla servis et.',
        'imageUrl':
            'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=1200',
        'durationMinutes': 35,
        'difficulty': 'Kolay',
      },
      {
        'title': 'Nohutlu Pirinç Pilavı',
        'description':
            'Tek başına doyurucu, ana yemeklerin yanına da uyumlu klasik pilav.',
        'ingredientNames': [
          'Pirinç',
          'Nohut',
          'Tereyağı',
          'Zeytinyağı',
          'Tuz',
          'Karabiber',
        ],
        'steps':
            'Pirinci yıka ve süz.\nTereyağı ile zeytinyağını ısıtıp pirinci kavur.\nNohut ve sıcak suyu ekle.\nKısık ateşte suyunu çekene kadar pişir.',
        'imageUrl':
            'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=1200',
        'durationMinutes': 30,
        'difficulty': 'Kolay',
      },
      {
        'title': 'Izgara Somon Salatası',
        'description':
            'Protein oranı yüksek, hafif ve renkli bir öğle yemeği seçeneği.',
        'ingredientNames': [
          'Somon',
          'Marul',
          'Roka',
          'Limon',
          'Zeytinyağı',
          'Tuz',
          'Karabiber',
        ],
        'steps':
            'Somonu tuz, karabiber ve limonla tatlandır.\nTavada ya da ızgarada pişir.\nYeşillikleri zeytinyağı ve limonla harmanla.\nSomonu salatanın üzerine alıp servis et.',
        'imageUrl':
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=1200',
        'durationMinutes': 25,
        'difficulty': 'Orta',
      },
    ];

    final existing = await _recipes.get();
    final existingTitles = existing.docs
        .map(
          (doc) => (doc.data()['title'] ?? '').toString().trim().toLowerCase(),
        )
        .where((title) => title.isNotEmpty)
        .toSet();
    final missingDefaults = defaults.where((item) {
      final title = (item['title'] ?? '').toString().trim().toLowerCase();
      return title.isNotEmpty && !existingTitles.contains(title);
    }).toList();

    if (missingDefaults.isEmpty) return 0;

    final batch = _db.batch();

    for (var index = 0; index < missingDefaults.length; index++) {
      final ref = _recipes.doc();
      final item = missingDefaults[index];
      final ingredientNames = List<String>.from(
        item['ingredientNames'] as List<dynamic>,
      );

      batch.set(ref, {
        'title': item['title'],
        'description': item['description'],
        'ingredients': ingredientNames.join('\n'),
        'ingredientsList': ingredientNames
            .map((name) => RecipeIngredient.fromName(name).toMap())
            .toList(),
        'steps': item['steps'],
        'imageUrl': item['imageUrl'],
        'durationMinutes': item['durationMinutes'],
        'difficulty': item['difficulty'],
        'authorId': 'system',
        'authorName': 'Cookla',
        'authorRole': 'admin',
        'status': 'approved',
        'createdAt': Timestamp.fromDate(now.subtract(Duration(days: index))),
        'approvedAt': Timestamp.fromDate(now),
        'approvedBy': approverUid,
        'dietitianApproved': false,
        'dietitianApprovedAt': null,
        'dietitianApprovedBy': null,
        'dietitianApprovedByName': null,
        'ratingAverage': 0,
        'ratingCount': 0,
        'likedBy': <String>[],
        'savedBy': <String>[],
      });
    }

    await batch.commit();
    return missingDefaults.length;
  }

  List<Recipe> _sortByCreatedAtDesc(List<Recipe> items) {
    final list = [...items];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<Recipe?> streamRecipe(String recipeId) {
    return _recipes.doc(recipeId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return Recipe.fromMap(doc.id, data);
    });
  }

  Stream<List<Recipe>> streamApprovedRecipes() {
    return _recipes
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(
          (snapshot) => _sortByCreatedAtDesc(
            snapshot.docs
                .map((doc) => Recipe.fromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  Stream<List<Recipe>> streamMyRecipes() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _recipes
        .where('authorId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) => _sortByCreatedAtDesc(
            snapshot.docs
                .map((doc) => Recipe.fromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  Stream<List<Recipe>> streamSavedRecipes() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _recipes
        .where('savedBy', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => _sortByCreatedAtDesc(
            snapshot.docs
                .map((doc) => Recipe.fromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  Stream<List<Recipe>> streamLikedRecipes() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _recipes
        .where('likedBy', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => _sortByCreatedAtDesc(
            snapshot.docs
                .map((doc) => Recipe.fromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  Stream<List<Recipe>> streamAllRecipes() {
    return _recipes.snapshots().map(
      (snapshot) => _sortByCreatedAtDesc(
        snapshot.docs.map((doc) => Recipe.fromMap(doc.id, doc.data())).toList(),
      ),
    );
  }

  Stream<List<Recipe>> streamPendingRecipes() {
    return _recipes
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => _sortByCreatedAtDesc(
            snapshot.docs
                .map((doc) => Recipe.fromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  Future<void> toggleLike(String recipeId) async {
    final user = await _requireUser();
    final ref = _recipes.doc(recipeId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw Exception('Tarif bulunamadı');

    final likedBy = List<String>.from(data['likedBy'] ?? const <String>[]);
    final alreadyLiked = likedBy.contains(user.uid);

    await ref.update({
      'likedBy': alreadyLiked
          ? FieldValue.arrayRemove([user.uid])
          : FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> toggleSave(String recipeId) async {
    final user = await _requireUser();
    final ref = _recipes.doc(recipeId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw Exception('Tarif bulunamadı');

    final savedBy = List<String>.from(data['savedBy'] ?? const <String>[]);
    final alreadySaved = savedBy.contains(user.uid);

    await ref.update({
      'savedBy': alreadySaved
          ? FieldValue.arrayRemove([user.uid])
          : FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> approveRecipe(String recipeId) async {
    final user = await _requireUser();
    await _ensureCanManageRecipes();

    await _recipes.doc(recipeId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': user.uid,
    });
  }

  Future<void> rejectRecipe(String recipeId) async {
    final user = await _requireUser();
    await _ensureCanManageRecipes();

    await _recipes.doc(recipeId).update({
      'status': 'rejected',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': user.uid,
      'dietitianApproved': false,
      'dietitianApprovedAt': null,
      'dietitianApprovedBy': null,
      'dietitianApprovedByName': null,
    });
  }

  Future<void> setDietitianApproval({
    required String recipeId,
    required bool approved,
  }) async {
    final user = await _requireUser();
    final userData = await _getMyUserData();
    final role = _normalizeRole(userData['role']);
    final status = (userData['status'] ?? '').toString().trim().toLowerCase();

    if ((role != 'dietitian' && role != 'admin') || status != 'approved') {
      throw Exception('Bu işlem için onaylı diyetisyen yetkisi gerekir.');
    }

    final ref = _recipes.doc(recipeId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw Exception('Tarif bulunamadı');

    final recipeStatus = (data['status'] ?? '').toString().trim().toLowerCase();
    if (recipeStatus != 'approved') {
      throw Exception('Sağlık rozeti sadece yayındaki tariflere verilebilir.');
    }

    final approverName = AppTextFormatters.displayName([
      (userData['name'] ?? '').toString().trim(),
      (userData['surname'] ?? '').toString().trim(),
    ]);

    await ref.update({
      'dietitianApproved': approved,
      'dietitianApprovedAt': approved ? FieldValue.serverTimestamp() : null,
      'dietitianApprovedBy': approved ? user.uid : null,
      'dietitianApprovedByName': approved
          ? (approverName.isEmpty ? 'Diyetisyen' : approverName)
          : null,
    });
  }

  Future<void> cookRecipeAndConsumePantry(Recipe recipe) async {
    final user = await _requireUser();
    final userRef = _users.doc(user.uid);
    final userDoc = await userRef.get();
    final data = userDoc.data() ?? {};
    final pantryItems = data['pantryItems'];

    if (pantryItems is! Iterable) {
      throw Exception(
        'Ölçülü malzeme listen yok. Önce Malzemelerim ekranından miktar gir.',
      );
    }

    // Miktar düşümü yalnızca aynı birime sahip ölçülerde yapılır; belirsiz ölçüler korunur.
    final updated = pantryItems.map((raw) {
      if (raw is! Map) return raw;
      final item = Map<String, dynamic>.from(raw);
      final title = (item['title'] ?? '').toString().trim().toLowerCase();
      final pantryAmount = (item['amount'] ?? '').toString().trim();

      final used = recipe.ingredientItems.where(
        (ingredient) => ingredient.name.trim().toLowerCase() == title,
      );

      var currentAmount = pantryAmount;
      for (final ingredient in used) {
        currentAmount = _subtractAmount(currentAmount, ingredient.amount);
      }

      item['amount'] = currentAmount;
      return item;
    }).toList();

    await userRef.set({
      'pantryItems': updated,
      'pantryUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _ensureCanManageRecipes();
    await _recipes.doc(recipeId).delete();
  }

  String _subtractAmount(String pantryAmount, String usedAmount) {
    final pantry = _ParsedAmount.tryParse(pantryAmount);
    final used = _ParsedAmount.tryParse(usedAmount);

    if (pantry == null || used == null) return pantryAmount;
    if (pantry.unit != used.unit) return pantryAmount;

    final remaining = pantry.value - used.value;
    final safeRemaining = remaining < 0 ? 0.0 : remaining;
    return _formatAmount(safeRemaining, pantry.unit);
  }

  String _formatAmount(double value, String unit) {
    final number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
    return unit.isEmpty ? number : '$number $unit';
  }
}

class _ParsedAmount {
  final double value;
  final String unit;

  const _ParsedAmount(this.value, this.unit);

  static _ParsedAmount? tryParse(String text) {
    final match = RegExp(r'^\s*(\d+(?:[,.]\d+)?)\s*(.*)$').firstMatch(text);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null) return null;
    final unit = (match.group(2) ?? '').trim().toLowerCase();
    return _ParsedAmount(value, unit);
  }
}
