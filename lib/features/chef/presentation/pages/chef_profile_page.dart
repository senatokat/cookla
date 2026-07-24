import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/text_formatters.dart';
import 'package:flutter_application_1/features/chef/data/follow_service.dart';

class ChefProfilePage extends StatelessWidget {
  final String chefId;

  const ChefProfilePage({super.key, required this.chefId});

  static const accent = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();

    return Scaffold(
      appBar: AppBar(title: const Text("Şef Profili")),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(chefId)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Şef bulunamadı"));
          }

          final data = snapshot.data!.data() ?? {};

          final name = (data['name'] ?? '').toString();
          final surname = (data['surname'] ?? '').toString();
          final photoUrl = (data['photoUrl'] ?? '').toString();
          final role = (data['role'] ?? 'chef').toString();
          final followersCount = data['followersCount'] ?? 0;
          final followingCount = data['followingCount'] ?? 0;

          final fullName = AppTextFormatters.displayName([
            name,
            surname,
          ], fallback: 'İsimsiz Şef');

          final hasPhoto = photoUrl.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: hasPhoto
                            ? NetworkImage(photoUrl)
                            : null,

                        child: !hasPhoto
                            ? const Icon(Icons.person, size: 36)
                            : null,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "👥 $followersCount takipçi   •   $followingCount takip edilen",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 14),

                      StreamBuilder<bool>(
                        stream: followService.isFollowing(chefId),

                        builder: (context, snap) {
                          final isFollowing = snap.data ?? false;

                          return SizedBox(
                            width: 150,
                            height: 44,

                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? Colors.grey
                                    : accent,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),

                              onPressed: () async {
                                try {
                                  if (isFollowing) {
                                    await followService.unfollow(chefId);
                                  } else {
                                    await followService.follow(chefId);
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("İşlem başarısız: $e"),
                                    ),
                                  );
                                }
                              },

                              child: Text(
                                isFollowing ? "Takiptesin" : "Takip Et",
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  "Workshoplar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('workshops')
                      .where('createdBy', isEqualTo: chefId)
                      .snapshots(),

                  builder: (context, workshopSnap) {
                    if (!workshopSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final docs = workshopSnap.data!.docs;

                    if (docs.isEmpty) {
                      return _EmptyBox(text: "Bu şefe ait workshop bulunamadı");
                    }

                    return Column(
                      children: docs.map((doc) {
                        final w = doc.data();

                        final title = (w['title'] ?? '').toString();
                        final location = (w['location'] ?? '').toString();
                        final chefName = (w['chefName'] ?? '').toString();

                        DateTime? date;
                        final rawDate = w['date'];
                        if (rawDate is Timestamp) {
                          date = rawDate.toDate();
                        }

                        final dateText = date == null
                            ? "Tarih yok"
                            : "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? "İsimsiz Workshop" : title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text("👨‍🍳 $chefName"),

                              const SizedBox(height: 4),

                              Text("📍 $location"),

                              const SizedBox(height: 4),

                              Text("📅 $dateText"),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 22),

                const Text(
                  "Tarifler",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('recipes')
                      .where('authorId', isEqualTo: chefId)
                      .snapshots(),

                  builder: (context, recipeSnap) {
                    if (!recipeSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final docs = recipeSnap.data!.docs;

                    if (docs.isEmpty) {
                      return _EmptyBox(text: "Bu şefe ait tarif bulunamadı");
                    }

                    return Column(
                      children: docs.map((doc) {
                        final r = doc.data();

                        final title = (r['title'] ?? '').toString();
                        final description = (r['description'] ?? '').toString();

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? "İsimsiz Tarif" : title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),

                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}
