import 'package:flutter/material.dart';

import '../../models/recipe.dart';
import 'recipe_detail_page.dart';

class RecipeCollectionPage extends StatelessWidget {
  final String title;
  final String emptyText;
  final Stream<List<Recipe>> stream;

  const RecipeCollectionPage({
    super.key,
    required this.title,
    required this.emptyText,
    required this.stream,
  });

  String _fmt(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<Recipe>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Hata: ${snap.error}'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(emptyText, textAlign: TextAlign.center),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final recipe = items[index];
              final isDietitianRecipe = recipe.authorRole == 'dietitian';

              return Material(
                color: isDietitianRecipe
                    ? const Color(0xFFFBFFFD)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailPage(recipe: recipe),
                      ),
                    );
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDietitianRecipe
                            ? const Color(0xFF2EAD7A)
                            : const Color(0xFFEAEAEA),
                        width: isDietitianRecipe ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1EC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Color(0xFFE65F5C),
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
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recipe.authorName,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              if (isDietitianRecipe) ...[
                                const SizedBox(height: 6),
                                const _DietitianRecipeLabel(),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                _fmt(recipe.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Color(0xFFE65F5C),
                                ),
                                const SizedBox(width: 4),
                                Text('${recipe.likeCount}'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bookmark,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Text('${recipe.saveCount}'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF00796B),
        ),
      ),
    );
  }
}
