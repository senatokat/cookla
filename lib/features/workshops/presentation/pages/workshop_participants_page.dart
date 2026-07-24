import 'package:flutter/material.dart';

import '../../../../services/workshop_participants_service.dart';
import '../../models/workshop.dart';
import '../../models/workshop_attendee.dart';

class WorkshopParticipantsPage extends StatefulWidget {
  final Workshop workshop;

  const WorkshopParticipantsPage({super.key, required this.workshop});

  @override
  State<WorkshopParticipantsPage> createState() =>
      _WorkshopParticipantsPageState();
}

class _WorkshopParticipantsPageState extends State<WorkshopParticipantsPage> {
  final WorkshopParticipantsService _svc = WorkshopParticipantsService();
  final Set<String> _busyIds = <String>{};

  late Future<bool> _canMarkFuture;

  @override
  void initState() {
    super.initState();
    _canMarkFuture = _svc.canMarkAttendance(widget.workshop.id);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _mark(String uid, String status) async {
    if (_busyIds.contains(uid)) return;

    setState(() {
      _busyIds.add(uid);
    });

    try {
      await _svc.markAttendance(
        workshopId: widget.workshop.id,
        uid: uid,
        attendanceStatus: status,
      );

      _snack(
        status == 'attended'
            ? 'Katıldı olarak işaretlendi'
            : 'Katılmadı olarak işaretlendi',
      );
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(uid);
        });
      }
    }
  }

  String _attendanceText(String status) {
    switch (status) {
      case 'attended':
        return 'Katıldı';
      case 'absent':
        return 'Katılmadı';
      default:
        return 'Bekliyor';
    }
  }

  Color _attendanceColor(String status) {
    switch (status) {
      case 'attended':
        return Colors.green;
      case 'absent':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _statusChip(String status) {
    final color = _attendanceColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _attendanceText(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildParticipantCard({
    required WorkshopAttendee attendee,
    required bool canMark,
  }) {
    final isBusy = _busyIds.contains(attendee.uid);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attendee.userName.isEmpty
                  ? 'İsimsiz kullanıcı'
                  : attendee.userName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(attendee.userEmail.isEmpty ? '-' : attendee.userEmail),
            if (canMark) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Katılım: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  _statusChip(attendee.attendanceStatus),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isBusy
                          ? null
                          : () => _mark(attendee.uid, 'absent'),
                      child: Text(isBusy ? 'İşleniyor...' : 'Katılmadı'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isBusy
                          ? null
                          : () => _mark(attendee.uid, 'attended'),
                      child: Text(isBusy ? 'İşleniyor...' : 'Katıldı'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canMarkFuture,
      builder: (context, authSnap) {
        final canMark = authSnap.data ?? false;

        return Scaffold(
          appBar: AppBar(title: const Text('Onaylanan Katılımcılar')),
          body: StreamBuilder<List<WorkshopAttendee>>(
            stream: _svc.streamApprovedParticipants(widget.workshop.id),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Hata: ${snap.error}'));
              }

              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snap.data ?? [];

              if (items.isEmpty) {
                return const Center(
                  child: Text('Henüz onaylanan katılımcı yok.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final attendee = items[index];
                  return _buildParticipantCard(
                    attendee: attendee,
                    canMark: canMark,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
