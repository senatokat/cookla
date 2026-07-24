import 'package:flutter/material.dart';

import '../../data/recipe_service.dart';
import '../../models/recipe.dart';

class PendingRecipesPage extends StatefulWidget {
  const PendingRecipesPage({super.key});

  @override
  State<PendingRecipesPage> createState() => _PendingRecipesPageState();
}

class _PendingRecipesPageState extends State<PendingRecipesPage> {
  static const Color accent = Color(0xFFE65F5C);
  final RecipeService _svc = RecipeService();
  final Set<String> _busyIds = <String>{};

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleAction({
    required Recipe recipe,
    required bool approve,
  }) async {
    if (_busyIds.contains(recipe.id)) return;

    setState(() {
      _busyIds.add(recipe.id);
    });

    try {
      if (approve) {
        await _svc.approveRecipe(recipe.id);
        _snack('Tarif onaylandı');
      } else {
        await _svc.rejectRecipe(recipe.id);
        _snack('Tarif reddedildi');
      }
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(recipe.id);
        });
      }
    }
  }

  String _fmt(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    return '$day.$month.$year';
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9E3DE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withAlpha(90)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          );

    return filled
        ? ElevatedButton(onPressed: onPressed, style: style, child: Text(text))
        : OutlinedButton(onPressed: onPressed, style: style, child: Text(text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      appBar: AppBar(
        title: const Text('Onay Bekleyen Tarifler'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<List<Recipe>>(
        stream: _svc.streamPendingRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data!;

          if (recipes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Şu anda onay bekleyen tarif yok.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: recipes.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFEEE7), Color(0xFFFFF7F1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent.withAlpha(22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_outlined,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kontrol bekleyen tarifler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${recipes.length} tarif sırada. Uygun bulduklarını hızlıca onaylayabilirsin.',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final recipe = recipes[index - 1];
              final isBusy = _busyIds.contains(recipe.id);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0E8E2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                recipe.authorName.isEmpty
                                    ? 'Anonim kullanıcı'
                                    : recipe.authorName,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2EC),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Beklemede',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _metaChip(
                          Icons.calendar_today_outlined,
                          _fmt(recipe.createdAt),
                        ),
                        _metaChip(
                          Icons.timer_outlined,
                          recipe.durationMinutes == null
                              ? 'Süre yok'
                              : '${recipe.durationMinutes} dk',
                        ),
                        _metaChip(
                          Icons.local_fire_department_outlined,
                          (recipe.difficulty?.trim().isNotEmpty ?? false)
                              ? recipe.difficulty!.trim()
                              : 'Kolay',
                        ),
                      ],
                    ),
                    if (recipe.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        recipe.description.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            text: isBusy ? 'İşleniyor...' : 'Reddet',
                            color: Colors.redAccent,
                            onPressed: isBusy
                                ? null
                                : () => _handleAction(
                                    recipe: recipe,
                                    approve: false,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionButton(
                            text: isBusy ? 'İşleniyor...' : 'Onayla',
                            color: accent,
                            filled: true,
                            onPressed: isBusy
                                ? null
                                : () => _handleAction(
                                    recipe: recipe,
                                    approve: true,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
