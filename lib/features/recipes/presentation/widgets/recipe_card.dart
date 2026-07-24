import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';

import '../../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onSaveTap;
  final bool isLiked;
  final bool isSaved;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onLikeTap,
    this.onSaveTap,
    this.isLiked = false,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        recipe.imageUrl != null && recipe.imageUrl!.trim().isNotEmpty;
    final isDietitianRecipe = recipe.authorRole == 'dietitian';

    return SizedBox(
      width: 208,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: isDietitianRecipe ? const Color(0xFFFBFFFD) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDietitianRecipe ? const Color(0xFF2EAD7A) : kBorder,
                width: isDietitianRecipe ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDietitianRecipe
                      ? const Color(0xFF2EAD7A).withAlpha(22)
                      : Colors.black.withAlpha(10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: SizedBox(
                        height: 126,
                        width: double.infinity,
                        child: hasImage
                            ? Image.network(
                                recipe.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imageFallback(),
                              )
                            : _imageFallback(),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _difficultyText(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (recipe.dietitianApproved)
                      Positioned(
                        left: 10,
                        top: 48,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F6F1).withAlpha(245),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.health_and_safety_outlined,
                                size: 13,
                                color: Color(0xFF00897B),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Diyetisyen',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00796B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Column(
                        children: [
                          _overlayAction(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isLiked ? kPrimary : kTextPrimary,
                            onTap: onLikeTap,
                          ),
                          const SizedBox(height: 8),
                          _overlayAction(
                            icon: isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: kTextPrimary,
                            onTap: onSaveTap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: kTextPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recipe.authorName.isEmpty
                              ? 'Anonim şef'
                              : recipe.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextSecondary,
                          ),
                        ),
                        if (isDietitianRecipe) ...[
                          const SizedBox(height: 7),
                          const _DietitianRecipeBadge(),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              size: 14,
                              color: kTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _durationText(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimary.withAlpha(26), kPrimarySoft],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _StatPill(
                                      icon: Icons.favorite,
                                      color: kPrimary,
                                      value: '${recipe.likeCount}',
                                    ),
                                    _StatPill(
                                      icon: Icons.bookmark,
                                      color: kTextPrimary,
                                      value: '${recipe.saveCount}',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: kTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _overlayAction({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF1E8), Color(0xFFFFD4C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_menu, size: 38, color: kPrimary),
    );
  }

  String _durationText() {
    final value = recipe.durationMinutes;
    if (value == null || value <= 0) return 'Süre belirtilmedi';
    return '$value dk';
  }

  String _difficultyText() {
    final text = recipe.difficulty?.trim() ?? '';
    if (text.isEmpty) return 'Kolay';
    return text;
  }
}

class _DietitianRecipeBadge extends StatelessWidget {
  const _DietitianRecipeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFE5D8)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 13,
            color: Color(0xFF00796B),
          ),
          SizedBox(width: 4),
          Text(
            'Diyetisyen tarifi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00796B),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;

  const _StatPill({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }
}
