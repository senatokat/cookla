import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/models/ingredient_data.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/ingredient_chip.dart';

class PantrySection extends StatelessWidget {
  final List<IngredientData> ingredients;
  final Set<String> selectedIngredients;
  final ValueChanged<IngredientData> onIngredientTap;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;

  const PantrySection({
    super.key,
    required this.ingredients,
    required this.selectedIngredients,
    required this.onIngredientTap,
    this.onSelectAll,
    this.onClearSelection,
  });

  static const Color muted = Color(0xFF7E7671);

  @override
  Widget build(BuildContext context) {
    final hasIngredients = ingredients.isNotEmpty;
    final allSelected =
        hasIngredients && selectedIngredients.length == ingredients.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                title: 'Evde Olanlar',
                subtitle:
                    'Seçtiklerin tarif önerilerini ve alışveriş listesini belirler.',
              ),
            ),
            if (hasIngredients)
              TextButton(
                onPressed: allSelected ? onClearSelection : onSelectAll,
                child: Text(allSelected ? 'Temizle' : 'Tumunu seç'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (!hasIngredients)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF0E3DB)),
            ),
            child: const Text(
              'Tercihler ekranindan malzeme seçtiğinde burada gorunur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, height: 1.35),
            ),
          )
        else
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ingredients.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final ingredient = ingredients[index];
                final selected = selectedIngredients.contains(ingredient.title);

                return IngredientChip(
                  data: ingredient,
                  selected: selected,
                  onTap: () => onIngredientTap(ingredient),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: PantrySection.muted, height: 1.35),
        ),
      ],
    );
  }
}
