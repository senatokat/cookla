import 'package:flutter/material.dart';

import '../../data/recipe_service.dart';
import '../../models/recipe.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final RecipeService _svc = RecipeService();
  bool _deleting = false;
  bool _acting = false;
  bool _healthApproving = false;
  bool _cooking = false;

  String _two(int n) => n.toString().padLeft(2, '0');

  String _fmt(DateTime d) {
    return '${_two(d.day)}.${_two(d.month)}.${d.year} '
        '${_two(d.hour)}:${_two(d.minute)}';
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }

  Future<void> _deleteRecipe() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tarifi sil'),
          content: const Text('Bu tarifi silmek istediğine emin misin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() => _deleting = true);

    try {
      await _svc.deleteRecipe(widget.recipe.id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarif silindi.')));

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _toggleLike(Recipe recipe) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await _svc.toggleLike(recipe.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _toggleSave(Recipe recipe) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await _svc.toggleSave(recipe.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<List<Object?>> _loadPermissions() {
    return Future.wait<Object?>([
      _svc.getMyRole(),
      _svc.canGiveDietitianApproval(),
    ]);
  }

  Future<void> _toggleDietitianApproval(Recipe recipe) async {
    if (_healthApproving) return;
    setState(() => _healthApproving = true);

    try {
      await _svc.setDietitianApproval(
        recipeId: recipe.id,
        approved: !recipe.dietitianApproved,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recipe.dietitianApproved
                ? 'Sağlık rozeti kaldirildi.'
                : 'Sağlık rozeti eklendi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _healthApproving = false);
    }
  }

  Future<void> _cookRecipe(Recipe recipe) async {
    if (_cooking) return;
    setState(() => _cooking = true);

    try {
      await _svc.cookRecipeAndConsumePantry(recipe);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Malzeme stoklarin güncellendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _cooking = false);
    }
  }

  Widget _dietitianApprovalPanel({
    required Recipe recipe,
    required bool canGiveDietitianApproval,
  }) {
    if (!recipe.dietitianApproved && !canGiveDietitianApproval) {
      return const SizedBox.shrink();
    }

    final approver = recipe.dietitianApprovedByName?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFE5D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                color: Color(0xFF00897B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recipe.dietitianApproved
                      ? 'Diyetisyen sağlık rozeti var'
                      : 'Diyetisyen sağlık rozeti yok',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00695C),
                  ),
                ),
              ),
            ],
          ),
          if (recipe.dietitianApproved &&
              approver != null &&
              approver.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Onaylayan: $approver',
              style: const TextStyle(color: Color(0xFF00695C)),
            ),
          ],
          if (canGiveDietitianApproval && recipe.status == 'approved') ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _healthApproving
                  ? null
                  : () => _toggleDietitianApproval(recipe),
              icon: _healthApproving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      recipe.dietitianApproved
                          ? Icons.remove_circle_outline
                          : Icons.verified_outlined,
                    ),
              label: Text(
                recipe.dietitianApproved
                    ? 'Sağlık rozetini kaldir'
                    : 'Sağlık rozeti ver',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFFFFF1EC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _acting ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? const Color(0xFFE65F5C)
                    : const Color(0xFFEAEAEA),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? const Color(0xFFE65F5C) : Colors.black54,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFFE65F5C)
                          : Colors.black87,
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

  Widget _section(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(value),
      ],
    );
  }

  Widget _ingredientsSection(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Malzemeler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: recipe.ingredientItems
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6F1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.amount.trim().isEmpty
                        ? '${item.emoji} ${item.name}'
                        : '${item.emoji} ${item.name} - ${item.amount.trim()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Recipe?>(
      stream: _svc.streamRecipe(widget.recipe.id),
      builder: (context, recipeSnap) {
        final recipe = recipeSnap.data ?? widget.recipe;

        return FutureBuilder<List<Object?>>(
          future: _loadPermissions(),
          builder: (context, snap) {
            final role = snap.data?[0] as String?;
            final canGiveDietitianApproval = snap.data?[1] == true;
            final canDelete = role == 'chef' || role == 'admin';
            final uid = _svc.currentUid;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Tarif Detayı'),
                actions: [
                  if (_deleting)
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (canDelete)
                    IconButton(
                      onPressed: _deleteRecipe,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Tarifi Sil',
                    ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _metaChip(Icons.person_outline, recipe.authorName),
                        _metaChip(Icons.badge_outlined, recipe.authorRole),
                        _metaChip(
                          Icons.info_outline,
                          _statusText(recipe.status),
                        ),
                        if (recipe.dietitianApproved)
                          _metaChip(
                            Icons.health_and_safety_outlined,
                            'Diyetisyen onaylı',
                          ),
                        _metaChip(
                          Icons.calendar_today_outlined,
                          _fmt(recipe.createdAt),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _actionPill(
                          icon: recipe.isLikedBy(uid)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          text: 'Beğen (${recipe.likeCount})',
                          selected: recipe.isLikedBy(uid),
                          onTap: () => _toggleLike(recipe),
                        ),
                        const SizedBox(width: 10),
                        _actionPill(
                          icon: recipe.isSavedBy(uid)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          text: 'Kaydet (${recipe.saveCount})',
                          selected: recipe.isSavedBy(uid),
                          onTap: () => _toggleSave(recipe),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _cooking ? null : () => _cookRecipe(recipe),
                        icon: _cooking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.restaurant),
                        label: const Text('Tarifi Yaptim'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _dietitianApprovalPanel(
                      recipe: recipe,
                      canGiveDietitianApproval: canGiveDietitianApproval,
                    ),
                    if (recipe.dietitianApproved ||
                        (canGiveDietitianApproval &&
                            recipe.status == 'approved'))
                      const SizedBox(height: 20),
                    _section('Açıklama', recipe.description),
                    const SizedBox(height: 20),
                    _ingredientsSection(recipe),
                    const SizedBox(height: 20),
                    _section('Hazırlanış', recipe.steps),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.black54),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
