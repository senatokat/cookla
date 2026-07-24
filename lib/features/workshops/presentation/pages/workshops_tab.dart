// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';

import '../../../../core/app_clock.dart';
import '../../../../core/role_norm.dart';
import '../../../../services/workshop_service.dart';
import '../../models/workshop.dart';
import '../widgets/workshop_card.dart';
import 'create_workshop_page.dart';
import 'workshop_detail_page.dart';

enum _WorkshopViewMode { list, calendar }

class WorkshopsTab extends StatefulWidget {
  final String? uid;

  const WorkshopsTab({super.key, required this.uid});

  @override
  State<WorkshopsTab> createState() => _WorkshopsTabState();
}

class _WorkshopsTabState extends State<WorkshopsTab> {
  final WorkshopService _svc = WorkshopService();
  _WorkshopViewMode _viewMode = _WorkshopViewMode.list;

  void _openDetail(BuildContext context, Workshop workshop) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkshopDetailPage(workshop: workshop)),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateWorkshopPage()),
    );
  }

  Future<void> _deleteWorkshop(BuildContext context, Workshop workshop) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Workshop silinsin mi?'),
        content: Text('“${workshop.title}” kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _svc.deleteWorkshop(workshop.id);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workshop silindi')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _svc.getMyRole(),
      builder: (context, roleSnap) {
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final role = roleSnap.data;
        final isAdmin = isAdminRole(role);
        final canCreate = isChefRole(role);

        return Scaffold(
          floatingActionButton: _WorkshopsFab(
            visible: canCreate,
            onPressed: () => _openCreate(context),
          ),
          body: _WorkshopsContent(
            service: _svc,
            isAdmin: isAdmin,
            viewMode: _viewMode,
            onViewModeChanged: (mode) => setState(() => _viewMode = mode),
            onOpenDetail: (workshop) => _openDetail(context, workshop),
            onDelete: (workshop) => _deleteWorkshop(context, workshop),
          ),
        );
      },
    );
  }
}

class _WorkshopsFab extends StatelessWidget {
  final bool visible;
  final VoidCallback onPressed;

  const _WorkshopsFab({required this.visible, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}

class _WorkshopsContent extends StatelessWidget {
  final WorkshopService service;
  final bool isAdmin;
  final _WorkshopViewMode viewMode;
  final ValueChanged<_WorkshopViewMode> onViewModeChanged;
  final ValueChanged<Workshop> onOpenDetail;
  final ValueChanged<Workshop> onDelete;

  const _WorkshopsContent({
    required this.service,
    required this.isAdmin,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onOpenDetail,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Workshop>>(
      stream: service.streamWorkshops(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Hata: ${snap.error}'));
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snap.data ?? [];

        if (items.isEmpty) {
          return const _EmptyWorkshopsView();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Workshoplar',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PopupMenuButton<_WorkshopViewMode>(
                    initialValue: viewMode,
                    onSelected: onViewModeChanged,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _WorkshopViewMode.list,
                        child: Row(
                          children: [
                            Icon(Icons.view_agenda_outlined),
                            SizedBox(width: 8),
                            Text('Liste olarak'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _WorkshopViewMode.calendar,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_outlined),
                            SizedBox(width: 8),
                            Text('Takvim olarak'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            viewMode == _WorkshopViewMode.calendar
                                ? Icons.calendar_month_outlined
                                : Icons.view_agenda_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            viewMode == _WorkshopViewMode.calendar
                                ? 'Takvim'
                                : 'Liste',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: viewMode == _WorkshopViewMode.calendar
                  ? _WorkshopCalendarView(
                      items: items,
                      isAdmin: isAdmin,
                      onOpenDetail: onOpenDetail,
                      onDelete: onDelete,
                    )
                  : _WorkshopListView(
                      items: items,
                      isAdmin: isAdmin,
                      onOpenDetail: onOpenDetail,
                      onDelete: onDelete,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _WorkshopListView extends StatelessWidget {
  final List<Workshop> items;
  final bool isAdmin;
  final ValueChanged<Workshop> onOpenDetail;
  final ValueChanged<Workshop> onDelete;

  const _WorkshopListView({
    required this.items,
    required this.isAdmin,
    required this.onOpenDetail,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final workshop = items[i];

        return GestureDetector(
          onLongPress: isAdmin ? () => onDelete(workshop) : null,
          child: WorkshopCard(
            workshop: workshop,
            onTap: () => onOpenDetail(workshop),
          ),
        );
      },
    );
  }
}

class _WorkshopCalendarView extends StatefulWidget {
  final List<Workshop> items;
  final bool isAdmin;
  final ValueChanged<Workshop> onOpenDetail;
  final ValueChanged<Workshop> onDelete;

  const _WorkshopCalendarView({
    required this.items,
    required this.isAdmin,
    required this.onOpenDetail,
    required this.onDelete,
  });

  @override
  State<_WorkshopCalendarView> createState() => _WorkshopCalendarViewState();
}

class _WorkshopCalendarViewState extends State<_WorkshopCalendarView> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final first = widget.items.isEmpty
        ? AppClock.now()
        : widget.items.first.date;
    _visibleMonth = DateTime(first.year, first.month);
    _selectedDay = DateTime(first.year, first.month, first.day);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Workshop> _itemsFor(DateTime day) {
    return widget.items.where((item) => _sameDay(item.date, day)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<DateTime> _calendarDays() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final startOffset = (firstDay.weekday + 6) % 7;
    final start = firstDay.subtract(Duration(days: startOffset));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  void _moveMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _calendarDays();
    final selectedItems = _itemsFor(_selectedDay);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _moveMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _moveMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  _WeekdayLabel('Pzt'),
                  _WeekdayLabel('Sal'),
                  _WeekdayLabel('Car'),
                  _WeekdayLabel('Per'),
                  _WeekdayLabel('Cum'),
                  _WeekdayLabel('Cmt'),
                  _WeekdayLabel('Paz'),
                ],
              ),
              const SizedBox(height: 6),
              GridView.builder(
                itemCount: days.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final count = _itemsFor(day).length;
                  final inMonth = day.month == _visibleMonth.month;
                  final selected = _sameDay(day, _selectedDay);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE65F5C)
                            : inMonth
                            ? const Color(0xFFFFF6F1)
                            : Colors.black.withAlpha(5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white
                                  : inMonth
                                  ? Colors.black87
                                  : Colors.black38,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(height: 3),
                            Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFFE65F5C),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: selected
                                      ? const Color(0xFFE65F5C)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_selectedDay.day} ${_monthName(_selectedDay.month)} workshoplari',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (selectedItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
            ),
            child: const Text('Bugün için workshop yok.'),
          )
        else
          ...selectedItems.map(
            (workshop) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onLongPress: widget.isAdmin
                    ? () => widget.onDelete(workshop)
                    : null,
                child: WorkshopCard(
                  workshop: workshop,
                  onTap: () => widget.onOpenDetail(workshop),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;

  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _monthName(int month) {
  const names = [
    'Ocak',
    'Subat',
    'Mart',
    'Nisan',
    'Mayis',
    'Hazıran',
    'Temmuz',
    'Agustos',
    'Eylul',
    'Ekim',
    'Kasim',
    'Aralik',
  ];
  return names[month - 1];
}

class _EmptyWorkshopsView extends StatelessWidget {
  const _EmptyWorkshopsView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Henüz workshop yok.'));
  }
}
