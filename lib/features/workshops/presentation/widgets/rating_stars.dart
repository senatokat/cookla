import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final double size;
  final bool readOnly;

  const RatingStars({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 28,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;

        final icon = Icon(
          star <= value ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );

        if (readOnly) return icon;

        return GestureDetector(
          onTap: () => onChanged?.call(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: icon,
          ),
        );
      }),
    );
  }
}
