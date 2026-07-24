import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';

import '../../models/ingredient_data.dart';

class IngredientChip extends StatelessWidget {
  final IngredientData data;
  final bool selected;
  final VoidCallback? onTap;

  const IngredientChip({
    super.key,
    required this.data,
    this.selected = false,
    this.onTap,
  });

  static const accent = kPrimary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withAlpha(28)
                    : Colors.black.withAlpha(8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? accent : Colors.black12,
                  width: selected ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(data.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 66,
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? accent : Colors.black87,
                  ),
                ),
                if (data.amount.trim().isNotEmpty)
                  Text(
                    data.amount.trim(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
