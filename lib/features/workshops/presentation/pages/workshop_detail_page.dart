import 'package:flutter/material.dart';

import '../../../../core/role_norm.dart';
import '../../../../services/workshop_service.dart';
import '../../models/workshop.dart';
import '../widgets/request_join_sheet.dart';
import '../widgets/review_section.dart';
import 'workshop_participants_page.dart';
import 'workshop_requests_page.dart';

class WorkshopDetailPage extends StatelessWidget {
  final Workshop workshop;

  WorkshopDetailPage({super.key, required this.workshop});

  final _svc = WorkshopService();

  void _openJoin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => RequestJoinSheet(workshopId: workshop.id),
    );
  }

  void _openRequests(BuildContext context, Workshop workshop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkshopRequestsPage(workshop: workshop),
      ),
    );
  }

  void _openParticipants(BuildContext context, Workshop workshop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkshopParticipantsPage(workshop: workshop),
      ),
    );
  }

  Future<void> _deleteWorkshop(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Workshop silinsin mi?'),
        content: const Text('Bu workshop kalıcı olarak silinecek.'),
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

      Navigator.pop(context);

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

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year  $hour:$minute';
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return 'Belirtilmedi';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '$h saat $m dk';
    if (h > 0) return '$h saat';
    return '$m dk';
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
    Color? color,
  }) {
    final baseColor = color ?? Colors.orange;
    final foreground = color ?? Colors.orange.shade800;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipeBlock(String title, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(text.trim().isEmpty ? 'Bilgi girilmemiş.' : text.trim()),
        ],
      ),
    );
  }

  Widget _recipeSection(WorkshopRecipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workshop Tarifi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _recipeBlock('Tarif Adı', recipe.title),
        const SizedBox(height: 12),
        _recipeBlock('Malzemeler', recipe.ingredients),
        const SizedBox(height: 12),
        _recipeBlock('Yapılış', recipe.steps),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Workshop>(
      stream: _svc.streamWorkshop(workshop.id),
      builder: (context, workshopSnap) {
        if (workshopSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!workshopSnap.hasData) {
          return const Scaffold(
            body: Center(child: Text('Workshop bulunamadı')),
          );
        }

        final w = workshopSnap.data!;
        final dateText = _formatDate(w.date);

        return FutureBuilder<String?>(
          future: _svc.getMyRole(),
          builder: (context, roleSnap) {
            final role = roleSnap.data;
            final canRequest = canRequestWorkshop(role);
            final isAdmin = isAdminRole(role);

            return FutureBuilder<bool>(
              future: _svc.canManageRequests(w.id),
              builder: (context, manageSnap) {
                final canManage = manageSnap.data ?? false;

                return Scaffold(
                  appBar: AppBar(
                    title: Text(w.title),
                    actions: [
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteWorkshop(context),
                        ),
                    ],
                  ),
                  body: StreamBuilder<int>(
                    stream: _svc.streamApprovedCount(w.id),
                    builder: (context, countSnap) {
                      final approvedCount = countSnap.data ?? 0;
                      final isFull = approvedCount >= w.capacity;

                      return StreamBuilder<JoinRequest?>(
                        stream: _svc.streamMyRequest(w.id),
                        builder: (context, requestSnap) {
                          final req = requestSnap.data;
                          final canViewRecipe =
                              canManage ||
                              (req?.status == RequestStatus.approved &&
                                  req?.attendanceStatus == 'attended');

                          String joinText = 'Katıl';
                          VoidCallback? joinAction = () => _openJoin(context);

                          if (!canRequest) {
                            joinText = 'Yetkin yok';
                            joinAction = null;
                          } else if (isFull) {
                            joinText = 'Kontenjan dolu';
                            joinAction = null;
                          } else if (req != null) {
                            if (req.status == RequestStatus.pending) {
                              joinText = 'Beklemede';
                              joinAction = null;
                            } else if (req.status == RequestStatus.approved) {
                              joinText = 'Onaylandı';
                              joinAction = null;
                            } else if (req.status == RequestStatus.rejected) {
                              joinText = 'Tekrar dene';
                            }
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${w.ratingAverage.toStringAsFixed(1)} (${w.ratingCount})',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _metaRow(
                                  Icons.location_on_outlined,
                                  w.location,
                                ),
                                _metaRow(Icons.event_outlined, dateText),
                                _metaRow(Icons.person_outline, w.chefsLabel),
                                _metaRow(
                                  Icons.groups_outlined,
                                  '$approvedCount / ${w.capacity}',
                                ),
                                _metaRow(
                                  Icons.schedule_outlined,
                                  _formatDuration(w.durationMinutes),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                Text(
                                  w.description.isEmpty
                                      ? 'Açıklama yok'
                                      : w.description,
                                ),
                                const SizedBox(height: 24),
                                ReviewSection(workshopId: w.id),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _openParticipants(context, w),
                                    child: const Text(
                                      'Onaylanan Katılımcıları Gör',
                                    ),
                                  ),
                                ),
                                if (canManage) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _openRequests(context, w),
                                      child: const Text('İstekleri Yönet'),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if (w.hasPendingCoChef)
                                  _infoCard(
                                    icon: Icons.hourglass_top_outlined,
                                    title: 'İkinci şef onayı bekleniyor',
                                    text:
                                        '${w.coChefName ?? 'Davet edilen şef'} bu workshop davetini kabul ettiginde birlikte yönetebilecek.',
                                    color: Colors.blue,
                                  ),
                                if (w.hasPendingCoChef)
                                  const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: joinAction,
                                    child: Text(joinText),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (w.hasRecipe)
                                  canViewRecipe
                                      ? _recipeSection(w.recipe!)
                                      : _infoCard(
                                          icon: Icons.lock_outline,
                                          title: 'Tarif kilitli',
                                          text:
                                              'Bu tarife sadece şefin "katıldı" olarak işaretlediği kullanıcılar erişebilir.',
                                        ),
                                if (req?.status == RequestStatus.approved &&
                                    req?.attendanceStatus == 'pending' &&
                                    !canManage) ...[
                                  const SizedBox(height: 12),
                                  _infoCard(
                                    icon: Icons.info_outline,
                                    title: 'Katılım bekleniyor',
                                    text:
                                        'Şef seni workshop sonrası "katıldı" olarak işaretlediğinde tarif açılacak.',
                                    color: Colors.blue,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
