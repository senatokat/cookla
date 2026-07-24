import 'package:flutter/material.dart';

class BadgeWidget extends StatelessWidget {
  final String text;

  final Color color;

  const BadgeWidget({
    super.key,
    required this.text,
    this.color = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(38), // 0.15 opacity ≈ 38 alpha
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
