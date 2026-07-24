import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/features/recipes/models/recipe.dart';
import 'package:flutter_application_1/features/recipes/presentation/widgets/recipe_card.dart'
    as recipe_ui;

class RecommendedRecipesSection extends StatelessWidget {
  final List<Recipe> recipes;
  final bool loading;
  final bool hasSelectedIngredients;
  final String? currentUid;
  final Set<String> selectedForShopping;
  final ValueChanged<Recipe> onRecipeTap;
  final ValueChanged<Recipe> onLikeTap;
  final ValueChanged<Recipe> onSaveTap;
  final ValueChanged<Recipe> onToggleShoppingRecipe;

  const RecommendedRecipesSection({
    super.key,
    required this.recipes,
    required this.loading,
    required this.hasSelectedIngredients,
    required this.currentUid,
    required this.selectedForShopping,
    required this.onRecipeTap,
    required this.onLikeTap,
    required this.onSaveTap,
    required this.onToggleShoppingRecipe,
  });

  static const Color muted = kTextSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sana Uyan Tarifler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          hasSelectedIngredients
              ? 'Listeye eklemek istediklerini seç. Seçmediğin tarifler alışveriş listesine karismaz.'
              : 'Tarif önermek için önce malzeme seçimi yap.',
          style: const TextStyle(color: muted, height: 1.35),
        ),
        const SizedBox(height: 14),
        if (loading)
          const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!hasSelectedIngredients)
          const _SectionPlaceholder(
            title: 'Malzeme seçimi bekleniyor',
            subtitle:
                'Evde olan ürünleri isaretlediginde tarif listesi burada olusacak.',
          )
        else if (recipes.isEmpty)
          const _SectionPlaceholder(
            title: 'Eslesen tarif bulunamadı',
            subtitle:
                'Baska malzemeler seçerek veya Tarifler sekmesinden yeni tarif ekleyerek tekrar deneyebilirsin.',
          )
        else
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                final selected = selectedForShopping.contains(recipe.id);

                return SizedBox(
                  width: 208,
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: recipe_ui.RecipeCard(
                                recipe: recipe,
                                onTap: () => onRecipeTap(recipe),
                                onLikeTap: () => onLikeTap(recipe),
                                onSaveTap: () => onSaveTap(recipe),
                                isLiked: recipe.isLikedBy(currentUid),
                                isSaved: recipe.isSavedBy(currentUid),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: GestureDetector(
                                onTap: () => onToggleShoppingRecipe(recipe),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? kPrimary
                                        : Colors.white.withAlpha(230),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        selected
                                            ? Icons.check_circle
                                            : Icons.add_circle_outline,
                                        size: 15,
                                        color: selected
                                            ? Colors.white
                                            : kPrimary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        selected
                                            ? 'Listeye eklendi'
                                            : 'Listeye ekle',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          color: selected
                                              ? Colors.white
                                              : kPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionPlaceholder({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined, size: 28, color: kPrimary),
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
            style: const TextStyle(
              color: RecommendedRecipesSection.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
