import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../../../services/workshop_service.dart';
import 'rating_stars.dart';

class ReviewSection extends StatefulWidget {
  final String workshopId;

  const ReviewSection({super.key, required this.workshopId});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final _svc = WorkshopService();

  final _commentC = TextEditingController();

  int _selectedRating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _commentC.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack("Yorum yapmak için giriş yapmalısın");
      return;
    }

    final text = _commentC.text.trim();

    if (text.length < 3) {
      _snack("Yorum en az 3 karakter olmalı");
      return;
    }

    setState(() => _saving = true);

    try {
      await _svc.addOrUpdateReview(
        workshopId: widget.workshopId,
        rating: _selectedRating,
        comment: text,
      );

      _commentC.clear();

      _snack("Yorum kaydedildi");
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteMyReview() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Yorum silinsin mi?"),
        content: const Text("Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _svc.deleteMyReview(workshopId: widget.workshopId);
      _snack("Yorum silindi 🗑️");
    } catch (e) {
      _snack("Hata: $e");
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yorum Yap',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        RatingStars(
          value: _selectedRating,
          onChanged: (v) => setState(() => _selectedRating = v),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _commentC,
          maxLines: 3,
          enabled: !_saving,
          decoration: InputDecoration(
            hintText: 'Workshop hakkında düşünceni yaz...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Yorumu Gönder"),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Yorumlar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        StreamBuilder<List<WorkshopReview>>(
          stream: _svc.streamReviews(widget.workshopId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Text('Hata: ${snap.error}');
            }

            final reviews = snap.data ?? [];

            if (reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Henüz yorum yok. İlk yorumu sen yap.'),
              );
            }

            return Column(
              children: reviews.map((r) {
                final isMine = r.userId == myUid;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isMine)
                              IconButton(
                                onPressed: _deleteMyReview,
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),

                        RatingStars(value: r.rating, readOnly: true, size: 22),

                        const SizedBox(height: 6),

                        Text(r.comment),

                        const SizedBox(height: 6),

                        Text(
                          _formatDate(r.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
