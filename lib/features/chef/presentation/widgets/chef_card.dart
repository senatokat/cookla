import 'package:flutter/material.dart';

class ChefCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool isFollowing;
  final int followersCount;
  final String subtitle;
  final VoidCallback onFollowTap;
  final VoidCallback? onTap;

  const ChefCard({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.isFollowing,
    required this.followersCount,
    required this.subtitle,
    required this.onFollowTap,
    this.onTap,
  });

  static const accent = Color(0xFFE7A77E);

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0E7E2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF1E8), Color(0xFFFFDFC9)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.transparent,
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                  child: !hasPhoto
                      ? const Icon(Icons.person, color: Colors.black54)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$followersCount takipçi',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: isFollowing ? Colors.grey.shade300 : accent,
                  foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onFollowTap,
                child: Text(isFollowing ? 'Takiptesin' : 'Takip Et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
