import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/features/home/application/home_recommendation_helper.dart';
import 'package:flutter_application_1/features/recipes/models/recipe.dart';

class ShoppingListSection extends StatelessWidget {
  final List<ShoppingListItem> items;
  final List<Recipe> sourceRecipes;
  final bool hasSelectedIngredients;
  final VoidCallback? onSaveList;
  final bool saving;

  const ShoppingListSection({
    super.key,
    required this.items,
    required this.sourceRecipes,
    required this.hasSelectedIngredients,
    this.onSaveList,
    this.saving = false,
  });

  static const Color muted = kTextSecondary;

  @override
  Widget build(BuildContext context) {
    final sourceText = sourceRecipes.isEmpty
        ? 'Henüz tarif seçilmedi'
        : sourceRecipes.map((recipe) => recipe.title).take(3).join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alışveriş Listem',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          hasSelectedIngredients
              ? 'Seçilen tariflere göre eksik ürünleri burada göreceksin.'
              : 'Bu alan, seçtiğin malzemeler ve tariflere göre eksik ürünleri hesaplar.',
          style: const TextStyle(color: muted, height: 1.35),
        ),
        const SizedBox(height: 14),
        if (!hasSelectedIngredients)
          const _ShoppingPlaceholder(
            title: 'Önce malzeme seç',
            subtitle:
                'Malzeme seçimi yaptığında tariflere göre eksik ürünleri burada göreceksin.',
          )
        else if (sourceRecipes.isEmpty)
          const _ShoppingPlaceholder(
            title: 'Tarif seçimi bekleniyor',
            subtitle:
                'Listeye eklemek istediğin tarifleri seç. Seçmediğin hiçbir tarif alışveriş listesine eklenmez.',
          )
        else if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kSecondarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline, color: kSecondary, size: 30),
                SizedBox(height: 10),
                Text(
                  'Seçtiğin tarifler için ekstra ürüne ihtiyacın yok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: kPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sourceText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: items
                      .map(
                        (item) => ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width - 68,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_shopping_cart_outlined,
                                  size: 18,
                                  color: kPrimary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    item.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimarySoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${item.recipeCount} tarif',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: kPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saving ? null : onSaveList,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Kaydediliyor...' : 'Listeyi kaydet'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ShoppingPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ShoppingPlaceholder({required this.title, required this.subtitle});

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
          const Icon(Icons.shopping_basket_outlined, size: 28, color: kPrimary),
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
              color: ShoppingListSection.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
