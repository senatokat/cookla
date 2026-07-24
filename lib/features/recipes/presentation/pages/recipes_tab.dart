import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';

import '../../data/recipe_service.dart';
import '../../models/recipe.dart';
import '../widgets/recipe_card.dart';
import 'create_recipe_page.dart';
import 'pending_recipes_page.dart';
import 'recipe_detail_page.dart';

class RecipesTab extends StatefulWidget {
  const RecipesTab({super.key});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  final RecipeService _svc = RecipeService();
  final TextEditingController _searchCtrl = TextEditingController();

  static const Color accent = kPrimary;
  static const Color soft = kPrimarySoft;
  static const Color ink = kTextPrimary;
  static const Color muted = kTextSecondary;

  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getMyRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.data()?['role']?.toString().toLowerCase();
  }

  List<Recipe> _filterRecipes(List<Recipe> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((recipe) {
      return recipe.title.toLowerCase().contains(q) ||
          recipe.authorName.toLowerCase().contains(q) ||
          recipe.description.toLowerCase().contains(q) ||
          recipe.ingredientNames.any((item) => item.toLowerCase().contains(q));
    }).toList();
  }

  void _openRecipe(BuildContext context, Recipe recipe) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe)));
  }

  Future<void> _toggleLike(BuildContext context, Recipe recipe) async {
    try {
      await _svc.toggleLike(recipe.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _toggleSave(BuildContext context, Recipe recipe) async {
    try {
      await _svc.toggleSave(recipe.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  void _openPending(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PendingRecipesPage()));
  }

  Widget _searchBox() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E5DE)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Tarif, şef veya açıklama ara...',
                border: InputBorder.none,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.close, color: muted),
            ),
        ],
      ),
    );
  }

  Widget _heroCard({
    required int approvedCount,
    required int myCount,
    required bool canSeePending,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEEE8), Color(0xFFFFF9F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarifleri Keşfet',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Topluluğun paylaştığı lezzetleri incele, kendi tariflerini takip et.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (canSeePending)
                FilledButton.tonalIcon(
                  onPressed: () => _openPending(context),
                  style: FilledButton.styleFrom(
                    foregroundColor: accent,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Bekleyenler'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Onaylı Tarif',
                  value: approvedCount.toString(),
                  icon: Icons.verified_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Benim Tariflerim',
                  value: myCount.toString(),
                  icon: Icons.menu_book_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getMyRole(),
      builder: (context, roleSnap) {
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFFBF8),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = roleSnap.data ?? '';
        final canSeePending = role == 'chef' || role == 'admin';

        return Scaffold(
          backgroundColor: const Color(0xFFFFFBF8),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: accent,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateRecipePage()),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Yeni Tarif',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: SafeArea(
            child: StreamBuilder<List<Recipe>>(
              stream: _svc.streamApprovedRecipes(),
              builder: (context, approvedSnap) {
                if (approvedSnap.hasError) {
                  return _ErrorView(message: approvedSnap.error.toString());
                }

                return StreamBuilder<List<Recipe>>(
                  stream: _svc.streamMyRecipes(),
                  builder: (context, mySnap) {
                    if (mySnap.hasError) {
                      return _ErrorView(message: mySnap.error.toString());
                    }

                    final approvedRecipes = _filterRecipes(
                      approvedSnap.data ?? [],
                    );
                    final myRecipes = _filterRecipes(mySnap.data ?? []);

                    final loadingApproved =
                        approvedSnap.connectionState == ConnectionState.waiting;
                    final loadingMine =
                        mySnap.connectionState == ConnectionState.waiting;

                    if (loadingApproved && loadingMine) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: Column(
                              children: [
                                _heroCard(
                                  approvedCount: approvedSnap.data?.length ?? 0,
                                  myCount: mySnap.data?.length ?? 0,
                                  canSeePending: canSeePending,
                                  context: context,
                                ),
                                const SizedBox(height: 16),
                                _searchBox(),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                            child: _SectionHeader(
                              title: 'Öne Çıkan Tarifler',
                              subtitle:
                                  'Yeni onaylanan ve toplulukta öne çıkan tarifler',
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 308,
                            child: loadingApproved
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : approvedRecipes.isEmpty
                                ? const _EmptyPanel(
                                    title: 'Tarif bulunamadı',
                                    subtitle:
                                        'Aramayı temizleyip tekrar deneyebilirsin.',
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      16,
                                      0,
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: approvedRecipes.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final recipe = approvedRecipes[index];
                                      final uid = _svc.currentUid;

                                      return RecipeCard(
                                        recipe: recipe,
                                        onTap: () =>
                                            _openRecipe(context, recipe),
                                        onLikeTap: () =>
                                            _toggleLike(context, recipe),
                                        onSaveTap: () =>
                                            _toggleSave(context, recipe),
                                        isLiked: recipe.isLikedBy(uid),
                                        isSaved: recipe.isSavedBy(uid),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                            child: _SectionHeader(
                              title: 'Benim Paylaştıklarım',
                              subtitle:
                                  'Gönderdiğin tariflerin güncel durumunu buradan takip et.',
                            ),
                          ),
                        ),
                        if (loadingMine)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        else if (myRecipes.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, 14, 16, 20),
                              child: _EmptyPanel(
                                title: 'Henüz tarif göndermedin',
                                subtitle:
                                    'Sağ alttaki butonla ilk tarifini paylaşabilirsin.',
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                            sliver: SliverList.separated(
                              itemCount: myRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = myRecipes[index];

                                return _MyRecipeTile(
                                  recipe: recipe,
                                  onTap: () => _openRecipe(context, recipe),
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Bir hata oluştu:\n$message', textAlign: TextAlign.center),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _RecipesTabState.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: _RecipesTabState.muted, height: 1.35),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _RecipesTabState.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _RecipesTabState.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _RecipesTabState.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyPanel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E8E2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.restaurant_menu_outlined,
            color: _RecipesTabState.accent,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _RecipesTabState.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _DietitianRecipeLabel extends StatelessWidget {
  const _DietitianRecipeLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFE5D8)),
      ),
      child: const Text(
        'Diyetisyen tarifi',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF00796B),
        ),
      ),
    );
  }
}

class _MyRecipeTile extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _MyRecipeTile({required this.recipe, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }

  String _fmt(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(recipe.status);
    final isDietitianRecipe = recipe.authorRole == 'dietitian';

    return Material(
      color: isDietitianRecipe ? const Color(0xFFFBFFFD) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDietitianRecipe
                  ? const Color(0xFF2EAD7A)
                  : const Color(0xFFF0E8E2),
              width: isDietitianRecipe ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: _RecipesTabState.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _RecipesTabState.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recipe.authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _RecipesTabState.muted,
                      ),
                    ),
                    if (isDietitianRecipe) ...[
                      const SizedBox(height: 6),
                      const _DietitianRecipeLabel(),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      _fmt(recipe.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _RecipesTabState.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusText(recipe.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
