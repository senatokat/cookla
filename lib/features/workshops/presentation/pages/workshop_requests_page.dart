import 'package:flutter/material.dart';
import '../../../../services/workshop_service.dart';
import '../../models/workshop.dart';

class WorkshopRequestsPage extends StatefulWidget {
  final Workshop workshop;

  const WorkshopRequestsPage({super.key, required this.workshop});

  @override
  State<WorkshopRequestsPage> createState() => _WorkshopRequestsPageState();
}

class _WorkshopRequestsPageState extends State<WorkshopRequestsPage> {
  final WorkshopService _svc = WorkshopService();

  late Future<bool> _canManageFuture;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _canManageFuture = _svc.canManageRequests(widget.workshop.id);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _approve(String uid) async {
    if (_busyIds.contains(uid)) return;

    setState(() {
      _busyIds.add(uid);
    });

    try {
      await _svc.approveRequest(workshopId: widget.workshop.id, uid: uid);
      _snack('İstek onaylandı');
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

  Future<void> _reject(String uid) async {
    if (_busyIds.contains(uid)) return;

    setState(() {
      _busyIds.add(uid);
    });

    try {
      await _svc.rejectRequest(workshopId: widget.workshop.id, uid: uid);
      _snack('İstek reddedildi ❌');
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

  Color _statusColor(String status) {
    switch (status) {
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case RequestStatus.approved:
        return 'Onaylandı';
      case RequestStatus.rejected:
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canManageFuture,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final canManage = authSnap.data ?? false;

        if (!canManage) {
          return Scaffold(
            appBar: AppBar(title: const Text('Katılım İstekleri')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Bu workshop'ın isteklerini yönetme yetkin yok.",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Katılım İstekleri')),
          body: StreamBuilder<List<JoinRequest>>(
            stream: _svc.streamRequests(widget.workshop.id),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Hata: ${snap.error}'));
              }

              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snap.data ?? [];

              if (items.isEmpty) {
                return const Center(child: Text('Henüz katılım isteği yok.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final r = items[index];
                  final isPending = r.status == RequestStatus.pending;
                  final isBusy = _busyIds.contains(r.id);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.userName.isEmpty
                                ? 'İsimsiz kullanıcı'
                                : r.userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(r.userEmail.isEmpty ? '—' : r.userEmail),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Durum: ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _statusText(r.status),
                                style: TextStyle(
                                  color: _statusColor(r.status),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isPending)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => _reject(r.id),
                                    child: Text(
                                      isBusy ? 'İşleniyor...' : 'Reddet',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => _approve(r.id),
                                    child: Text(
                                      isBusy ? 'İşleniyor...' : 'Onayla',
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: null,
                                child: Text(_statusText(r.status)),
                              ),
                            ),
                        ],
                      ),
                    ),
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
