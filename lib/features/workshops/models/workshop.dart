import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/core/app_clock.dart';

class WorkshopRecipe {
  final String title;
  final String ingredients;
  final String steps;

  const WorkshopRecipe({
    required this.title,
    required this.ingredients,
    required this.steps,
  });

  bool get isEmpty =>
      title.trim().isEmpty &&
      ingredients.trim().isEmpty &&
      steps.trim().isEmpty;

  factory WorkshopRecipe.fromMap(Map<String, dynamic> data) {
    return WorkshopRecipe(
      title: (data['title'] ?? '').toString(),
      ingredients: (data['ingredients'] ?? '').toString(),
      steps: (data['steps'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'ingredients': ingredients, 'steps': steps};
  }
}

class Workshop {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String chefName;
  final String createdBy;
  final int capacity;
  final int durationMinutes;
  final double ratingAverage;
  final int ratingCount;
  final WorkshopRecipe? recipe;
  final String? coChefId;
  final String? coChefName;
  final String? coChefStatus;
  final String? coChefEmail;

  const Workshop({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.chefName,
    required this.createdBy,
    required this.capacity,
    required this.durationMinutes,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.recipe,
    this.coChefId,
    this.coChefName,
    this.coChefStatus,
    this.coChefEmail,
  });

  bool get hasRecipe => recipe != null && !recipe!.isEmpty;
  bool get hasPendingCoChef =>
      coChefId != null &&
      (coChefStatus ?? '').trim().toLowerCase() == 'pending';
  bool get hasAcceptedCoChef =>
      coChefId != null &&
      (coChefStatus ?? '').trim().toLowerCase() == 'accepted';

  String get chefsLabel {
    if (hasAcceptedCoChef &&
        coChefName != null &&
        coChefName!.trim().isNotEmpty) {
      return '$chefName + ${coChefName!.trim()}';
    }
    if (hasPendingCoChef &&
        coChefName != null &&
        coChefName!.trim().isNotEmpty) {
      return '$chefName + ${coChefName!.trim()} (onay bekliyor)';
    }
    return chefName;
  }

  factory Workshop.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final recipeData = data['recipe'];
    final rawDate = data['date'];

    DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate().toLocal();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate.toLocal();
    } else {
      parsedDate = AppClock.now();
    }

    return Workshop(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      date: parsedDate,
      chefName: (data['chefName'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      capacity: _parseInt(data['capacity']),
      durationMinutes: _parseInt(data['durationMinutes']),
      ratingAverage: _parseDouble(data['ratingAverage']),
      ratingCount: _parseInt(data['ratingCount']),
      recipe: recipeData is Map<String, dynamic>
          ? WorkshopRecipe.fromMap(recipeData)
          : null,
      coChefId: _readNullableText(data['coChefId']),
      coChefName: _readNullableText(data['coChefName']),
      coChefStatus: _readNullableText(data['coChefStatus']),
      coChefEmail: _readNullableText(data['coChefEmail']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'chefName': chefName,
      'createdBy': createdBy,
      'capacity': capacity,
      'durationMinutes': durationMinutes,
      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      'recipe': recipe?.toMap(),
      'coChefId': coChefId,
      'coChefName': coChefName,
      'coChefStatus': coChefStatus,
      'coChefEmail': coChefEmail,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _readNullableText(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }
}
