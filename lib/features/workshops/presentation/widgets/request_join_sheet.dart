import 'package:flutter/material.dart';

import '../../../../services/workshop_service.dart';

class RequestJoinSheet extends StatefulWidget {
  final String workshopId;

  const RequestJoinSheet({super.key, required this.workshopId});

  @override
  State<RequestJoinSheet> createState() => _RequestJoinSheetState();
}

class _RequestJoinSheetState extends State<RequestJoinSheet> {
  final WorkshopService _svc = WorkshopService();

  late final Future<String?> _roleFuture;
  late final Future<JoinRequesterIdentity> _identityFuture;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _roleFuture = _svc.getMyRole();
    _identityFuture = _svc.getCurrentRequesterIdentity();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _send(JoinRequesterIdentity identity) async {
    setState(() => _loading = true);

    try {
      await _svc.requestJoin(
        workshopId: widget.workshopId,
        userName: identity.name,
        userEmail: identity.email,
      );

      _snack('İstek gönderildi');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _accountInfo(JoinRequesterIdentity identity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withAlpha(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İstek bu hesap bilgileriyle gönderilecek:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(identity.name),
          const SizedBox(height: 4),
          Text(identity.email),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets;

    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, roleSnap) {
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final role = roleSnap.data;
        final canRequest = role == 'user' || role == 'student';

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: pad.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Katılım İsteği',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (!canRequest)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withAlpha(10),
                  ),
                  child: Text(
                    role == null
                        ? 'Giriş yapmalısın'
                        : 'Bu rol istek gönderemez',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                FutureBuilder<JoinRequesterIdentity>(
                  future: _identityFuture,
                  builder: (context, identitySnap) {
                    if (identitySnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (identitySnap.hasError || !identitySnap.hasData) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.red.withAlpha(18),
                        ),
                        child: Text(
                          identitySnap.error?.toString() ??
                              'Hesap bilgileri alınamadı.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final identity = identitySnap.data!;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _accountInfo(identity),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : () => _send(identity),
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('İstek Gönder'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
