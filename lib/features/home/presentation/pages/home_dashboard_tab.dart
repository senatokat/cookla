import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/text_formatters.dart';
import 'package:flutter_application_1/features/diet_plans/data/diet_plan_service.dart';
import 'package:flutter_application_1/features/diet_plans/models/weekly_diet_plan.dart';
import 'package:flutter_application_1/features/diet_plans/presentation/pages/weekly_diet_plans_page.dart';
import 'package:flutter_application_1/features/home/application/home_recommendation_helper.dart';
import 'package:flutter_application_1/features/home/models/ingredient_data.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_header_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/pantry_section.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/recommended_recipes_section.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/shopping_list_section.dart';
import 'package:flutter_application_1/features/recipes/data/recipe_service.dart';
import 'package:flutter_application_1/features/recipes/models/recipe.dart';
import 'package:flutter_application_1/features/recipes/presentation/pages/recipe_detail_page.dart';

class HomeDashboardTab extends StatelessWidget {
  final String? uid;

  const HomeDashboardTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null || uid!.isEmpty) {
      return const _HomeDashboardContent(
        uid: null,
        name: 'Kullanıcı',
        photoUrl: null,
        pantryIngredients: <IngredientData>[],
        savedShoppingRecipeIds: <String>[],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid!)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final rawName = (data?['name'] as String?)?.trim();
        final rawPhotoUrl = (data?['photoUrl'] as String?)?.trim();
        final pantryItems = data?['pantryItems'];
        final pantryIngredients = pantryItems is Iterable
            ? pantryItems
                  .whereType<Map>()
                  .map(
                    (item) =>
                        IngredientData.fromMap(Map<String, dynamic>.from(item)),
                  )
                  .where((item) => item.title.trim().isNotEmpty)
                  .toList()
            : <IngredientData>[];

        final ingredientNames = <String>{
          ...((data?['likedIngredients'] as List?) ?? [])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty),
          ...((data?['customIngredients'] as List?) ?? [])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty),
        }.toList()..sort();

        final savedShoppingRecipeIds =
            ((data?['shoppingListRecipeIds'] as List?) ?? [])
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList();

        return _HomeDashboardContent(
          uid: uid,
          name: AppTextFormatters.displayName([
            rawName ?? '',
          ], fallback: 'Kullanıcı'),
          photoUrl: rawPhotoUrl == null || rawPhotoUrl.isEmpty
              ? null
              : rawPhotoUrl,
          pantryIngredients: pantryIngredients.isNotEmpty
              ? pantryIngredients
              : ingredientNames.map(IngredientData.fromName).toList(),
          savedShoppingRecipeIds: savedShoppingRecipeIds,
        );
      },
    );
  }
}

class _HomeDashboardContent extends StatefulWidget {
  final String? uid;
  final String name;
  final String? photoUrl;
  final List<IngredientData> pantryIngredients;
  final List<String> savedShoppingRecipeIds;

  const _HomeDashboardContent({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.pantryIngredients,
    required this.savedShoppingRecipeIds,
  });

  @override
  State<_HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<_HomeDashboardContent> {
  final RecipeService _recipeService = RecipeService();
  final Set<String> _selectedIngredients = <String>{};
  final Set<String> _selectedShoppingRecipeIds = <String>{};
  bool _savingShoppingList = false;

  @override
  void initState() {
    super.initState();
    _syncSelectedIngredients(resetWhenEmpty: true);
    _syncSelectedShoppingRecipes(initial: true);
  }

  @override
  void didUpdateWidget(covariant _HomeDashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedIngredients(resetWhenEmpty: false);
    _syncSelectedShoppingRecipes(initial: false);
  }

  void _syncSelectedIngredients({required bool resetWhenEmpty}) {
    final titles = widget.pantryIngredients.map((item) => item.title).toSet();
    _selectedIngredients.removeWhere((item) => !titles.contains(item));

    if ((resetWhenEmpty && _selectedIngredients.isEmpty) ||
        (_selectedIngredients.isEmpty && titles.isNotEmpty)) {
      _selectedIngredients
        ..clear()
        ..addAll(titles);
    }
  }

  void _syncSelectedShoppingRecipes({required bool initial}) {
    if (initial || _selectedShoppingRecipeIds.isEmpty) {
      _selectedShoppingRecipeIds
        ..clear()
        ..addAll(widget.savedShoppingRecipeIds);
    }
  }

  void _toggleIngredient(IngredientData ingredient) {
    setState(() {
      if (_selectedIngredients.contains(ingredient.title)) {
        _selectedIngredients.remove(ingredient.title);
      } else {
        _selectedIngredients.add(ingredient.title);
      }
    });
  }

  void _selectAllIngredients() {
    setState(() {
      _selectedIngredients
        ..clear()
        ..addAll(widget.pantryIngredients.map((item) => item.title));
    });
  }

  void _clearSelectedIngredients() {
    setState(() {
      _selectedIngredients.clear();
    });
  }

  void _toggleShoppingRecipe(Recipe recipe) {
    setState(() {
      if (_selectedShoppingRecipeIds.contains(recipe.id)) {
        _selectedShoppingRecipeIds.remove(recipe.id);
      } else {
        _selectedShoppingRecipeIds.add(recipe.id);
      }
    });
  }

  void _openRecipe(BuildContext context, Recipe recipe) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe)));
  }

  Future<void> _toggleLike(BuildContext context, Recipe recipe) async {
    try {
      await _recipeService.toggleLike(recipe.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    }
  }

  Future<void> _toggleSave(BuildContext context, Recipe recipe) async {
    try {
      await _recipeService.toggleSave(recipe.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    }
  }

  Future<void> _saveShoppingList(BuildContext context) async {
    final uid = widget.uid;
    if (uid == null || uid.isEmpty) return;

    setState(() => _savingShoppingList = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'shoppingListRecipeIds': _selectedShoppingRecipeIds.toList(),
        'shoppingListUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alışveriş listesi tarif seçimlerin kaydedildi'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    } finally {
      if (mounted) {
        setState(() => _savingShoppingList = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBF8),
      child: StreamBuilder<List<Recipe>>(
        stream: _recipeService.streamApprovedRecipes(),
        builder: (context, snapshot) {
          final allRecipes = snapshot.data ?? const <Recipe>[];
          final recommended = HomeRecommendationHelper.recommendedRecipes(
            recipes: allRecipes,
            selectedIngredients: _selectedIngredients,
          );
          final selectedShoppingRecipes = allRecipes
              .where((recipe) => _selectedShoppingRecipeIds.contains(recipe.id))
              .toList();
          final shoppingItems = HomeRecommendationHelper.shoppingList(
            recipes: selectedShoppingRecipes,
            pantryIngredients: _selectedIngredients,
            recipeLimit: selectedShoppingRecipes.length,
          );

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    HomeHeaderCard(
                      name: widget.name,
                      photoUrl: widget.photoUrl,
                      selectedCount: _selectedIngredients.length,
                      recommendationCount: recommended.length,
                      shoppingItemCount: shoppingItems.length,
                    ),
                    const SizedBox(height: 24),
                    _ActiveDietPlanSection(uid: widget.uid),
                    const SizedBox(height: 24),
                    _LowStockSection(
                      items: widget.pantryIngredients
                          .where((item) => _isLowStock(item.amount))
                          .toList(),
                    ),
                    if (widget.pantryIngredients.any(
                      (item) => _isLowStock(item.amount),
                    ))
                      const SizedBox(height: 24),
                    PantrySection(
                      ingredients: widget.pantryIngredients,
                      selectedIngredients: _selectedIngredients,
                      onIngredientTap: _toggleIngredient,
                      onSelectAll: _selectAllIngredients,
                      onClearSelection: _clearSelectedIngredients,
                    ),
                    const SizedBox(height: 24),
                    RecommendedRecipesSection(
                      recipes: recommended,
                      loading:
                          snapshot.connectionState == ConnectionState.waiting,
                      hasSelectedIngredients: _selectedIngredients.isNotEmpty,
                      currentUid: _recipeService.currentUid,
                      selectedForShopping: _selectedShoppingRecipeIds,
                      onRecipeTap: (recipe) => _openRecipe(context, recipe),
                      onLikeTap: (recipe) => _toggleLike(context, recipe),
                      onSaveTap: (recipe) => _toggleSave(context, recipe),
                      onToggleShoppingRecipe: _toggleShoppingRecipe,
                    ),
                    const SizedBox(height: 24),
                    ShoppingListSection(
                      items: shoppingItems,
                      sourceRecipes: selectedShoppingRecipes,
                      hasSelectedIngredients: _selectedIngredients.isNotEmpty,
                      saving: _savingShoppingList,
                      onSaveList: selectedShoppingRecipes.isEmpty
                          ? null
                          : () => _saveShoppingList(context),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

bool _isLowStock(String amount) {
  final parsed = RegExp(r'^\s*(\d+(?:[,.]\d+)?)\s*(.*)$').firstMatch(amount);
  if (parsed == null) return false;
  final value = double.tryParse(parsed.group(1)!.replaceAll(',', '.'));
  if (value == null) return false;
  final unit = (parsed.group(2) ?? '').trim().toLowerCase();
  if (unit == 'kg' || unit == 'l' || unit == 'litre') return value <= 0.25;
  if (unit == 'g' || unit == 'gr' || unit == 'ml') return value <= 100;
  return value <= 1;
}

class _LowStockSection extends StatelessWidget {
  final List<IngredientData> items;

  const _LowStockSection({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD7A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE68000)),
              SizedBox(width: 8),
              Text(
                'Azalan Malzemelerim',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Chip(
                    label: Text(
                      '${item.emoji} ${item.title}'
                      '${item.amount.trim().isEmpty ? '' : ' - ${item.amount.trim()}'}',
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ActiveDietPlanSection extends StatelessWidget {
  final String? uid;

  const _ActiveDietPlanSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    final userId = uid;
    if (userId == null || userId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<WeeklyDietPlan?>(
      stream: DietPlanService().streamActivePlan(userId),
      builder: (context, snapshot) {
        final plan = snapshot.data;

        if (plan == null) {
          return const SizedBox.shrink();
        }

        return _DietPlanPromptCard(
          title: plan.title,
          subtitle: '${plan.dietitianName} tarafindan hazırlandı',
          buttonText: 'Programı Gör',
          active: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    WeeklyDietPlanDetailPage(plan: plan, canStartPlan: true),
              ),
            );
          },
        );
      },
    );
  }
}

class _DietPlanPromptCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;
  final bool active;

  const _DietPlanPromptCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F6F1) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? const Color(0xFFBFE5D8) : const Color(0xFFEDE3DD),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00897B).withAlpha(18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              active
                  ? Icons.check_circle_outline
                  : Icons.calendar_month_outlined,
              color: const Color(0xFF00897B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (active) ...[
                  const Text(
                    'Aktif Diyet Programın',
                    style: TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(onPressed: onTap, child: Text(buttonText)),
        ],
      ),
    );
  }
}
