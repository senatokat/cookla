// ignore_for_file: use_null_aware_elements

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/features/home/application/home_recommendation_helper.dart';
import 'package:flutter_application_1/features/recipes/data/recipe_service.dart';
import 'package:flutter_application_1/features/recipes/models/recipe.dart';

class ShoppingListPage extends StatelessWidget {
  final String uid;

  const ShoppingListPage({super.key, required this.uid});

  Future<void> _saveSelection({
    required List<String> recipeIds,
    List<String>? checkedItems,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'shoppingListRecipeIds': recipeIds,
      if (checkedItems != null) 'shoppingListCheckedItems': checkedItems,
      'shoppingListUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showRecipePicker(
    BuildContext context,
    List<Recipe> allRecipes,
    Set<String> selectedRecipeIds,
  ) async {
    final searchController = TextEditingController();
    var query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = allRecipes.where((recipe) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              return recipe.title.toLowerCase().contains(q) ||
                  recipe.authorName.toLowerCase().contains(q) ||
                  recipe.ingredientNames.any(
                    (item) => item.toLowerCase().contains(q),
                  );
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (value) => setSheetState(() => query = value),
                      decoration: const InputDecoration(
                        hintText: 'Tarif ara',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final recipe = filtered[index];
                          final selected = selectedRecipeIds.contains(
                            recipe.id,
                          );

                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: kBorder),
                            ),
                            title: Text(recipe.title),
                            subtitle: Text(
                              recipe.ingredientNames.take(3).join(', '),
                            ),
                            trailing: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: kPrimary,
                            ),
                            onTap: () async {
                              final nextIds = <String>{
                                ...selectedRecipeIds,
                                recipe.id,
                              }.toList();
                              await _saveSelection(recipeIds: nextIds);
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeService = RecipeService();

    return Scaffold(
      appBar: AppBar(title: const Text('Alışveriş Listem')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          final data = userSnapshot.data?.data();
          final recipeIds =
              ((data?['shoppingListRecipeIds'] as List?) ?? const [])
                  .map((item) => item.toString().trim())
                  .where((item) => item.isNotEmpty)
                  .toSet();
          final checkedItems =
              ((data?['shoppingListCheckedItems'] as List?) ?? const [])
                  .map((item) => item.toString().trim())
                  .where((item) => item.isNotEmpty)
                  .toSet();
          final pantryIngredients = <String>{
            ...((data?['likedIngredients'] as List?) ?? const [])
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty),
            ...((data?['customIngredients'] as List?) ?? const [])
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty),
          };

          return StreamBuilder<List<Recipe>>(
            stream: recipeService.streamApprovedRecipes(),
            builder: (context, recipesSnapshot) {
              final allRecipes = recipesSnapshot.data ?? const <Recipe>[];
              final selectedRecipes = allRecipes
                  .where((recipe) => recipeIds.contains(recipe.id))
                  .toList();
              final items = HomeRecommendationHelper.shoppingList(
                recipes: selectedRecipes,
                pantryIngredients: pantryIngredients,
                recipeLimit: selectedRecipes.length,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tariflerim',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            _showRecipePicker(context, allRecipes, recipeIds),
                        icon: const Icon(Icons.add),
                        label: const Text('Tarif ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (selectedRecipes.isEmpty)
                    const _EmptyState(
                      text:
                          'Henüz tarif seçmedin. Home ekranindan ya da bu sayfadan tarif ekleyebilirsin.',
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: selectedRecipes.map((recipe) {
                        return InputChip(
                          label: Text(recipe.title),
                          onDeleted: () async {
                            final nextIds = recipeIds.toSet()
                              ..remove(recipe.id);
                            await _saveSelection(
                              recipeIds: nextIds.toList(),
                              checkedItems: checkedItems.toList(),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Eksik Malzemeler',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (selectedRecipes.isEmpty)
                    const _EmptyState(
                      text: 'Liste oluşturmak için önce tarif seçmelisin.',
                    )
                  else if (items.isEmpty)
                    const _EmptyState(
                      text:
                          'Seçtiğin tarifler için ekstra ürüne ihtiyacın görünmüyor.',
                    )
                  else
                    ...items.map((item) {
                      final checked = checkedItems.contains(item.name);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF0E3DB)),
                        ),
                        child: CheckboxListTile(
                          value: checked,
                          onChanged: (value) async {
                            final nextChecked = checkedItems.toSet();
                            if (value == true) {
                              nextChecked.add(item.name);
                            } else {
                              nextChecked.remove(item.name);
                            }
                            await _saveSelection(
                              recipeIds: recipeIds.toList(),
                              checkedItems: nextChecked.toList(),
                            );
                          },
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: checked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text('${item.recipeCount} tarifte geciyor'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _saveSelection(
                        recipeIds: const <String>[],
                        checkedItems: const <String>[],
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Listeyi temizle'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E3DB)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(height: 1.35),
      ),
    );
  }
}
