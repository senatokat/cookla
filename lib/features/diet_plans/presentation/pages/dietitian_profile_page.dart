import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_clock.dart';
import 'package:flutter_application_1/core/text_formatters.dart';
import 'package:flutter_application_1/features/chef/data/follow_service.dart';
import 'package:flutter_application_1/features/diet_plans/data/diet_plan_service.dart';
import 'package:flutter_application_1/features/diet_plans/models/weekly_diet_plan.dart';
import 'package:flutter_application_1/features/diet_plans/presentation/pages/weekly_diet_plans_page.dart';
import 'package:flutter_application_1/features/recipes/models/recipe.dart';
import 'package:flutter_application_1/features/recipes/presentation/pages/recipe_detail_page.dart';

class DietitianProfilePage extends StatelessWidget {
  final String dietitianId;

  const DietitianProfilePage({super.key, required this.dietitianId});

  String _fullName(Map<String, dynamic> data) {
    final name = (data['name'] ?? '').toString().trim();
    final surname = (data['surname'] ?? '').toString().trim();
    return AppTextFormatters.displayName([
      name,
      surname,
    ], fallback: 'Diyetisyen');
  }

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();

    return Scaffold(
      appBar: AppBar(title: const Text('Diyetisyen Profili')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(dietitianId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text('Diyetisyen bulunamadı.'));
          }

          final data = snapshot.data!.data() ?? {};
          final name = _fullName(data);
          final photoUrl = (data['photoUrl'] ?? '').toString().trim();
          final followers = (data['followersCount'] ?? 0) as int;
          final following = (data['followingCount'] ?? 0) as int;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6F1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFE5D8)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 36)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'DIYETISYEN',
                      style: TextStyle(
                        color: Color(0xFF00897B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$followers takipci   -   $following takip edilen',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<bool>(
                      stream: followService.isFollowing(dietitianId),
                      builder: (context, snap) {
                        final isFollowing = snap.data ?? false;

                        return SizedBox(
                          width: 150,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? Colors.grey.shade300
                                  : const Color(0xFF00897B),
                              foregroundColor: isFollowing
                                  ? Colors.black87
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                if (isFollowing) {
                                  await followService.unfollow(dietitianId);
                                } else {
                                  await followService.follow(dietitianId);
                                }
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hata: $error')),
                                );
                              }
                            },
                            child: Text(
                              isFollowing ? 'Takiptesin' : 'Takip Et',
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
                'Diyet Programlari',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<WeeklyDietPlan>>(
                stream: DietPlanService().streamPlansByDietitian(dietitianId),
                builder: (context, planSnap) {
                  if (!planSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final plans = planSnap.data ?? const <WeeklyDietPlan>[];
                  if (plans.isEmpty) {
                    return const _EmptyBox(
                      text: 'Yayınlanmış diyet programı yok.',
                    );
                  }

                  return Column(
                    children: plans.map((plan) {
                      return _DietProgramCard(
                        plan: plan,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WeeklyDietPlanDetailPage(
                                plan: plan,
                                canStartPlan: true,
                                canSavePlan: true,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Tarifler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .where('authorId', isEqualTo: dietitianId)
                    .snapshots(),
                builder: (context, recipeSnap) {
                  if (!recipeSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final recipes = recipeSnap.data!.docs
                      .map((doc) => Recipe.fromMap(doc.id, doc.data()))
                      .toList();
                  if (recipes.isEmpty) {
                    return const _EmptyBox(text: 'Yayinlanmis tarif yok.');
                  }

                  return Column(
                    children: recipes.map((recipe) {
                      return _SimpleTile(
                        icon: Icons.restaurant_menu_outlined,
                        title: recipe.title,
                        subtitle: recipe.description,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailPage(recipe: recipe),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DietProgramCard extends StatelessWidget {
  final WeeklyDietPlan plan;
  final VoidCallback onTap;

  const _DietProgramCard({required this.plan, required this.onTap});

  int get plannedDayCount => plan.days.where((day) => day.hasAnyItem).length;

  int get itemCount {
    var count = 0;
    for (final day in plan.days) {
      if (day.breakfast != null) count++;
      if (day.lunch != null) count++;
      if (day.dinner != null) count++;
      count += day.snacks.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final note = plan.notes.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0ECE8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F6F1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF00897B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppClock.compactDate(plan.createdAt),
                            style: const TextStyle(
                              color: Colors.black45,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, height: 1.35),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ProgramMetric(
                        icon: Icons.view_week_outlined,
                        value: '$plannedDayCount gun',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgramMetric(
                        icon: Icons.restaurant_menu_outlined,
                        value: '$itemCount seçim',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgramMetric extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ProgramMetric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00897B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SimpleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00897B)),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
