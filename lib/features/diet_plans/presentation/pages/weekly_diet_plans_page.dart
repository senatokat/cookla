import 'package:flutter/material.dart';

import 'package:flutter_application_1/features/diet_plans/data/diet_plan_service.dart';
import 'package:flutter_application_1/features/diet_plans/models/weekly_diet_plan.dart';
import 'package:flutter_application_1/features/diet_plans/presentation/pages/create_weekly_diet_plan_page.dart';

class WeeklyDietPlansPage extends StatefulWidget {
  final bool manageOwn;
  final bool savedOnly;

  const WeeklyDietPlansPage({
    super.key,
    this.manageOwn = true,
    this.savedOnly = false,
  });

  @override
  State<WeeklyDietPlansPage> createState() => _WeeklyDietPlansPageState();
}

class _WeeklyDietPlansPageState extends State<WeeklyDietPlansPage> {
  final _service = DietPlanService();

  Future<void> _openCreate() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateWeeklyDietPlanPage()));
  }

  Future<void> _deletePlan(WeeklyDietPlan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Programi sil'),
        content: Text('${plan.title} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.deletePlan(plan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Program silindi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    }
  }

  String _fmt(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String get _title {
    if (widget.savedOnly) return 'Kaydettigim Diyetler';
    return widget.manageOwn
        ? 'Diyet Programlari'
        : 'Yayınlanan Diyet Programlari';
  }

  Stream<List<WeeklyDietPlan>> get _plansStream {
    if (widget.savedOnly) return _service.streamSavedPlans();
    return widget.manageOwn
        ? _service.streamMyPlans()
        : _service.streamPublishedPlans();
  }

  String get _emptyText {
    if (widget.savedOnly) return 'Henüz kaydettiğin diyet programı yok.';
    return widget.manageOwn
        ? 'Henüz haftalık diyet programı oluşturmadın.'
        : 'Henüz yayınlanan haftalık diyet programı yok.';
  }

  Future<void> _toggleSavePlan(WeeklyDietPlan plan) async {
    final wasSaved = plan.isSavedBy(_service.currentUid);

    try {
      await _service.toggleSavePlan(plan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved
                ? 'Diyet programı kayıtlardan kaldırıldı.'
                : 'Diyet programı kaydedildi.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      floatingActionButton: widget.manageOwn && !widget.savedOnly
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00897B),
              onPressed: _openCreate,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Yeni Program',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: StreamBuilder<List<WeeklyDietPlan>>(
        stream: _plansStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = snapshot.data ?? const <WeeklyDietPlan>[];
          if (plans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_emptyText, textAlign: TextAlign.center),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plan = plans[index];
              final canSave = !widget.manageOwn || widget.savedOnly;
              return _PlanCard(
                plan: plan,
                dateText: _fmt(plan.createdAt),
                isSaved: plan.isSavedBy(_service.currentUid),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WeeklyDietPlanDetailPage(
                        plan: plan,
                        canStartPlan: canSave,
                        canSavePlan: canSave,
                      ),
                    ),
                  );
                },
                onDelete: widget.manageOwn && !widget.savedOnly
                    ? () => _deletePlan(plan)
                    : null,
                onToggleSave: canSave ? () => _toggleSavePlan(plan) : null,
              );
            },
          );
        },
      ),
    );
  }
}

class WeeklyDietPlanDetailPage extends StatelessWidget {
  final WeeklyDietPlan plan;
  final bool canStartPlan;
  final bool canSavePlan;

  const WeeklyDietPlanDetailPage({
    super.key,
    required this.plan,
    this.canStartPlan = false,
    this.canSavePlan = false,
  });

  Future<void> _startPlan(BuildContext context, WeeklyDietPlan plan) async {
    try {
      await DietPlanService().startPlan(plan);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diyet programı uygulamaya alındı.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    }
  }

  Future<void> _finishPlan(BuildContext context) async {
    try {
      await DietPlanService().finishActivePlan();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diyet programı bitirildi.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    }
  }

  Future<void> _toggleSavePlan(
    BuildContext context,
    WeeklyDietPlan plan,
  ) async {
    final service = DietPlanService();
    final wasSaved = plan.isSavedBy(service.currentUid);

    try {
      await service.toggleSavePlan(plan.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved
                ? 'Diyet programı kayıtlardan kaldırıldı.'
                : 'Diyet programı kaydedildi.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!canSavePlan) return _buildScaffold(context, plan);

    return StreamBuilder<WeeklyDietPlan?>(
      stream: DietPlanService().streamPlan(plan.id),
      builder: (context, snapshot) {
        return _buildScaffold(context, snapshot.data ?? plan);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, WeeklyDietPlan currentPlan) {
    return Scaffold(
      appBar: AppBar(title: Text(currentPlan.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (currentPlan.notes.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(currentPlan.notes),
            ),
            const SizedBox(height: 14),
          ],
          if (canSavePlan)
            _SavePlanButton(
              plan: currentPlan,
              onToggle: () => _toggleSavePlan(context, currentPlan),
            ),
          if (canStartPlan)
            _StartOrFinishPlanButton(
              plan: currentPlan,
              onStart: () => _startPlan(context, currentPlan),
              onFinish: () => _finishPlan(context),
            ),
          ...currentPlan.days.map((day) => _PlanDayCard(day: day)),
        ],
      ),
    );
  }
}

class _SavePlanButton extends StatelessWidget {
  final WeeklyDietPlan plan;
  final VoidCallback onToggle;

  const _SavePlanButton({required this.plan, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final uid = DietPlanService().currentUid;
    if (uid == null || uid.isEmpty) return const SizedBox.shrink();

    final isSaved = plan.isSavedBy(uid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onToggle,
          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
          label: Text(
            isSaved
                ? 'Kaydedildi (${plan.saveCount})'
                : 'Kaydet (${plan.saveCount})',
          ),
        ),
      ),
    );
  }
}

class _StartOrFinishPlanButton extends StatelessWidget {
  final WeeklyDietPlan plan;
  final VoidCallback onStart;
  final VoidCallback onFinish;

  const _StartOrFinishPlanButton({
    required this.plan,
    required this.onStart,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final service = DietPlanService();
    final uid = service.currentUid;

    if (uid == null || uid.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<WeeklyDietPlan?>(
      stream: service.streamActivePlan(uid),
      builder: (context, snapshot) {
        final isActive = snapshot.data?.id == plan.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SizedBox(
            height: 50,
            child: isActive
                ? OutlinedButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Programi Bitir'),
                  )
                : FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Programa Basla'),
                  ),
          ),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final WeeklyDietPlan plan;
  final String dateText;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleSave;

  const _PlanCard({
    required this.plan,
    required this.dateText,
    required this.isSaved,
    required this.onTap,
    required this.onDelete,
    required this.onToggleSave,
  });

  int get itemCount {
    var count = 0;
    for (final day in plan.days) {
      if (day.breakfast != null) count++;
      if (day.lunch != null) count++;
      if (day.dinner != null) count++;
      count += day.snacks.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6E6E6)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF00897B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$dateText - $itemCount seçim',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                )
              else if (onToggleSave != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: isSaved ? 'Kayıttan cikar' : 'Kaydet',
                      onPressed: onToggleSave,
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? const Color(0xFF00897B) : null,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanDayCard extends StatelessWidget {
  final DietPlanDay day;

  const _PlanDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    if (!day.hasAnyItem) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.dayName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (day.breakfast != null)
            _MealLine(label: 'Kahvalti', meal: day.breakfast!),
          if (day.snacks.isNotEmpty)
            _SnackLine(label: 'Ara ogun', snack: day.snacks[0]),
          if (day.lunch != null) _MealLine(label: 'Ogle', meal: day.lunch!),
          if (day.snacks.length > 1)
            _SnackLine(label: 'Ara ogun', snack: day.snacks[1]),
          if (day.dinner != null) _MealLine(label: 'Akşam', meal: day.dinner!),
          if (day.snacks.length > 2)
            ...day.snacks
                .skip(2)
                .map((snack) => _SnackLine(label: 'Ara ogun', snack: snack)),
        ],
      ),
    );
  }
}

class _SnackLine extends StatelessWidget {
  final String label;
  final String snack;

  const _SnackLine({required this.label, required this.snack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 126,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00897B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              snack,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealLine extends StatelessWidget {
  final String label;
  final DietPlanMeal meal;

  const _MealLine({required this.label, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              meal.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
