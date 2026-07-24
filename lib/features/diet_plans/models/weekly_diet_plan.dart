import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/app_clock.dart';
import 'package:flutter_application_1/features/recipes/models/recipe.dart';

class DietPlanMeal {
  final String recipeId;
  final String title;
  final String authorName;
  final String? imageUrl;
  final int? durationMinutes;
  final String? difficulty;

  const DietPlanMeal({
    required this.recipeId,
    required this.title,
    required this.authorName,
    this.imageUrl,
    this.durationMinutes,
    this.difficulty,
  });

  factory DietPlanMeal.fromRecipe(Recipe recipe) {
    return DietPlanMeal(
      recipeId: recipe.id,
      title: recipe.title,
      authorName: recipe.authorName,
      imageUrl: recipe.imageUrl,
      durationMinutes: recipe.durationMinutes,
      difficulty: recipe.difficulty,
    );
  }

  factory DietPlanMeal.fromMap(Map<String, dynamic> map) {
    return DietPlanMeal(
      recipeId: _readString(map['recipeId']),
      title: _readString(map['title']),
      authorName: _readString(map['authorName']),
      imageUrl: _readNullableString(map['imageUrl']),
      durationMinutes: _readNullableInt(map['durationMinutes']),
      difficulty: _readNullableString(map['difficulty']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'title': title,
      'authorName': authorName,
      'imageUrl': imageUrl,
      'durationMinutes': durationMinutes,
      'difficulty': difficulty,
    };
  }
}

class DietPlanDay {
  final int dayIndex;
  final String dayName;
  final DietPlanMeal? breakfast;
  final DietPlanMeal? lunch;
  final DietPlanMeal? dinner;
  final List<String> snacks;

  const DietPlanDay({
    required this.dayIndex,
    required this.dayName,
    this.breakfast,
    this.lunch,
    this.dinner,
    this.snacks = const <String>[],
  });

  factory DietPlanDay.fromMap(Map<String, dynamic> map) {
    final meals = map['meals'] is Map
        ? Map<String, dynamic>.from(map['meals'] as Map)
        : <String, dynamic>{};

    return DietPlanDay(
      dayIndex: _readNullableInt(map['dayIndex']) ?? 0,
      dayName: _readString(map['dayName']),
      breakfast: _readMeal(meals['breakfast']),
      lunch: _readMeal(meals['lunch']),
      dinner: _readMeal(meals['dinner']),
      snacks: _readStringList(map['snacks']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayIndex': dayIndex,
      'dayName': dayName,
      'meals': {
        'breakfast': breakfast?.toMap(),
        'lunch': lunch?.toMap(),
        'dinner': dinner?.toMap(),
      },
      'snacks': snacks,
    };
  }

  bool get hasAnyItem =>
      breakfast != null || lunch != null || dinner != null || snacks.isNotEmpty;
}

class WeeklyDietPlan {
  final String id;
  final String title;
  final String notes;
  final String dietitianId;
  final String dietitianName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<DietPlanDay> days;
  final List<String> savedByIds;

  const WeeklyDietPlan({
    required this.id,
    required this.title,
    required this.notes,
    required this.dietitianId,
    required this.dietitianName,
    required this.createdAt,
    this.updatedAt,
    required this.days,
    this.savedByIds = const <String>[],
  });

  factory WeeklyDietPlan.fromMap(String id, Map<String, dynamic> map) {
    return WeeklyDietPlan(
      id: id,
      title: _readString(map['title']),
      notes: _readString(map['notes']),
      dietitianId: _readString(map['dietitianId']),
      dietitianName: _readString(map['dietitianName']),
      createdAt: _readDateTime(map['createdAt']) ?? AppClock.now(),
      updatedAt: _readDateTime(map['updatedAt']),
      days: _readDays(map['days']),
      savedByIds: _readStringList(map['savedBy']),
    );
  }

  int get saveCount => savedByIds.length;

  bool isSavedBy(String? uid) {
    if (uid == null || uid.isEmpty) return false;
    return savedByIds.contains(uid);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'notes': notes,
      'dietitianId': dietitianId,
      'dietitianName': dietitianName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'days': days.map((day) => day.toMap()).toList(),
      'savedBy': savedByIds,
    };
  }
}

DietPlanMeal? _readMeal(dynamic value) {
  if (value is Map) {
    final meal = DietPlanMeal.fromMap(Map<String, dynamic>.from(value));
    return meal.recipeId.isEmpty ? null : meal;
  }
  return null;
}

List<DietPlanDay> _readDays(dynamic value) {
  if (value is Iterable) {
    final days = value
        .whereType<Map>()
        .map((item) => DietPlanDay.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    days.sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
    return days;
  }
  return const <DietPlanDay>[];
}

String _readString(dynamic value) {
  return (value ?? '').toString().trim();
}

String? _readNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is Iterable) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const <String>[];
}
