import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/app_clock.dart';
import 'package:flutter_application_1/features/home/models/ingredient_data.dart';

class RecipeIngredient {
  final String name;
  final String emoji;
  final String amount;

  const RecipeIngredient({
    required this.name,
    required this.emoji,
    this.amount = '',
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    final rawName = (map['name'] ?? '').toString().trim();
    final normalizedName = IngredientData.fromName(rawName).title;
    return RecipeIngredient(
      name: normalizedName,
      emoji: (map['emoji'] ?? IngredientData.emojiFor(normalizedName))
          .toString()
          .trim(),
      amount: (map['amount'] ?? '').toString().trim(),
    );
  }

  factory RecipeIngredient.fromName(String name, {String amount = ''}) {
    final normalized = IngredientData.fromName(name).title;
    return RecipeIngredient(
      name: normalized,
      emoji: IngredientData.emojiFor(normalized),
      amount: amount.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'emoji': emoji, 'amount': amount};
  }
}

class Recipe {
  final String id;
  final String title;
  final String description;
  final List<RecipeIngredient> ingredientItems;
  final String steps;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final bool dietitianApproved;
  final DateTime? dietitianApprovedAt;
  final String? dietitianApprovedBy;
  final String? dietitianApprovedByName;
  final String? imageUrl;
  final int? durationMinutes;
  final String? difficulty;
  final double ratingAverage;
  final int ratingCount;
  final List<String> likedByIds;
  final List<String> savedByIds;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredientItems,
    required this.steps,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.dietitianApproved = false,
    this.dietitianApprovedAt,
    this.dietitianApprovedBy,
    this.dietitianApprovedByName,
    this.imageUrl,
    this.durationMinutes,
    this.difficulty,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.likedByIds = const <String>[],
    this.savedByIds = const <String>[],
  });

  int get likeCount => likedByIds.length;
  int get saveCount => savedByIds.length;
  String get ingredients => ingredientNames.join('\n');
  List<String> get ingredientNames =>
      ingredientItems.map((item) => item.name).toList(growable: false);

  bool isLikedBy(String? uid) {
    if (uid == null || uid.isEmpty) return false;
    return likedByIds.contains(uid);
  }

  bool isSavedBy(String? uid) {
    if (uid == null || uid.isEmpty) return false;
    return savedByIds.contains(uid);
  }

  factory Recipe.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = _readDateTime(map['createdAt']) ?? AppClock.now();
    final approvedAt = _readDateTime(map['approvedAt']);
    final dietitianApprovedAt = _readDateTime(map['dietitianApprovedAt']);

    return Recipe(
      id: id,
      title: _readString(map['title']),
      description: _readString(map['description']),
      ingredientItems: _readIngredients(
        map['ingredientsList'],
        fallbackText: _readString(map['ingredients']),
      ),
      steps: _readString(map['steps']),
      authorId: _readString(map['authorId']),
      authorName: _readString(map['authorName']),
      authorRole: _normalizeRole(map['authorRole']),
      status: _normalizeStatus(map['status']),
      createdAt: createdAt,
      approvedAt: approvedAt,
      approvedBy: _readNullableString(map['approvedBy']),
      dietitianApproved: map['dietitianApproved'] == true,
      dietitianApprovedAt: dietitianApprovedAt,
      dietitianApprovedBy: _readNullableString(map['dietitianApprovedBy']),
      dietitianApprovedByName: _readNullableString(
        map['dietitianApprovedByName'],
      ),
      imageUrl: _readNullableString(map['imageUrl']),
      durationMinutes: _readNullableInt(map['durationMinutes']),
      difficulty: _readNullableString(map['difficulty']),
      ratingAverage: _readNullableDouble(map['ratingAverage']) ?? 0,
      ratingCount: _readNullableInt(map['ratingCount']) ?? 0,
      likedByIds: _readStringList(map['likedBy']),
      savedByIds: _readStringList(map['savedBy']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'ingredientsList': ingredientItems.map((item) => item.toMap()).toList(),
      'steps': steps,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'dietitianApproved': dietitianApproved,
      'dietitianApprovedAt': dietitianApprovedAt != null
          ? Timestamp.fromDate(dietitianApprovedAt!)
          : null,
      'dietitianApprovedBy': dietitianApprovedBy,
      'dietitianApprovedByName': dietitianApprovedByName,
      'imageUrl': imageUrl,
      'durationMinutes': durationMinutes,
      'difficulty': difficulty,
      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      'likedBy': likedByIds,
      'savedBy': savedByIds,
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<RecipeIngredient>? ingredientItems,
    String? steps,
    String? authorId,
    String? authorName,
    String? authorRole,
    String? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    bool? dietitianApproved,
    DateTime? dietitianApprovedAt,
    String? dietitianApprovedBy,
    String? dietitianApprovedByName,
    String? imageUrl,
    int? durationMinutes,
    String? difficulty,
    double? ratingAverage,
    int? ratingCount,
    List<String>? likedByIds,
    List<String>? savedByIds,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredientItems: ingredientItems ?? this.ingredientItems,
      steps: steps ?? this.steps,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      dietitianApproved: dietitianApproved ?? this.dietitianApproved,
      dietitianApprovedAt: dietitianApprovedAt ?? this.dietitianApprovedAt,
      dietitianApprovedBy: dietitianApprovedBy ?? this.dietitianApprovedBy,
      dietitianApprovedByName:
          dietitianApprovedByName ?? this.dietitianApprovedByName,
      imageUrl: imageUrl ?? this.imageUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      difficulty: difficulty ?? this.difficulty,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      likedByIds: likedByIds ?? this.likedByIds,
      savedByIds: savedByIds ?? this.savedByIds,
    );
  }

  static String _readString(dynamic value) {
    return (value ?? '').toString().trim();
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static List<RecipeIngredient> _readIngredients(
    dynamic value, {
    required String fallbackText,
  }) {
    if (value is Iterable) {
      final items = value
          .whereType<Map>()
          .map(
            (item) => RecipeIngredient.fromMap(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.name.isNotEmpty)
          .toList();
      if (items.isNotEmpty) return items;
    }

    return fallbackText
        .split(RegExp(r'[\n,;]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(RecipeIngredient.fromName)
        .toList();
  }

  static String _normalizeRole(dynamic value) {
    final role = (value ?? '').toString().trim().toLowerCase();
    if (role.isEmpty) return 'user';
    return role;
  }

  static String _normalizeStatus(dynamic value) {
    final status = (value ?? '').toString().trim().toLowerCase();
    if (status == 'approved' || status == 'rejected' || status == 'pending') {
      return status;
    }
    return 'pending';
  }
}
