import 'package:cloud_firestore/cloud_firestore.dart';

class WorkshopReview {
  final String id;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const WorkshopReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory WorkshopReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};

    return WorkshopReview(
      id: doc.id,
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? 'Kullanıcı').toString(),
      rating: _parseInt(map['rating'], fallback: 5),
      comment: (map['comment'] ?? '').toString(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory WorkshopReview.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return WorkshopReview(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? 'Kullanıcı').toString(),
      rating: _parseInt(map['rating'], fallback: 5),
      comment: (map['comment'] ?? '').toString(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
