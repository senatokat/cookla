import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/features/chef/data/follow_service.dart';
import 'package:flutter_application_1/features/chef/presentation/pages/chef_profile_page.dart';
import 'package:flutter_application_1/features/chef/presentation/widgets/chef_card.dart';
import 'package:flutter_application_1/features/diet_plans/presentation/pages/dietitian_profile_page.dart';
import 'package:flutter_application_1/core/text_formatters.dart';

enum _DirectoryMode { chef, dietitian }

class ChefsTab extends StatefulWidget {
  const ChefsTab({super.key});

  @override
  State<ChefsTab> createState() => _ChefsTabState();
}

class _ChefsTabState extends State<ChefsTab> {
  final _searchCtrl = TextEditingController();
  final _followService = FollowService();

  String _query = '';
  _DirectoryMode _mode = _DirectoryMode.chef;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fullName(Map<String, dynamic> data) {
    final name = (data['name'] ?? '').toString().trim();
    final surname = (data['surname'] ?? '').toString().trim();
    return AppTextFormatters.displayName([
      name,
      surname,
    ], fallback: _mode == _DirectoryMode.chef ? 'Isimsiz şef' : 'Diyetisyen');
  }

  bool _matches(Map<String, dynamic> data) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final fullName = _fullName(data).toLowerCase();
    final email = (data['email'] ?? '').toString().toLowerCase();
    return fullName.contains(q) || email.contains(q);
  }

  void _setMode(_DirectoryMode mode) {
    setState(() {
      _mode = mode;
      _query = '';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wantedRole = _mode == _DirectoryMode.chef ? 'chef' : 'dietitian';
    final title = _mode == _DirectoryMode.chef ? 'Şef Ara' : 'Diyetisyen Ara';
    final description = _mode == _DirectoryMode.chef
        ? 'Onaylı şefleri keşfet, profillerini incele ve takip et.'
        : 'Diyetisyenleri keşfet, programlarını incele ve takip et.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ShortcutCard(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Şef Ara',
                  subtitle: 'Tarif ve profil',
                  selected: _mode == _DirectoryMode.chef,
                  onTap: () => _setMode(_DirectoryMode.chef),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShortcutCard(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Diyetisyen Ara',
                  subtitle: 'Program ve profil',
                  selected: _mode == _DirectoryMode.dietitian,
                  onTap: () => _setMode(_DirectoryMode.dietitian),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF1E8), Color(0xFFFFFAF6)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: _mode == _DirectoryMode.chef
                                ? 'Şef adı ya da e-posta ara...'
                                : 'Diyetisyen adı ya da e-posta ara...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _mode == _DirectoryMode.chef ? 'Şefler' : 'Diyetisyenler',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final role = (data['role'] ?? '').toString().toLowerCase();
                  final status = (data['status'] ?? '')
                      .toString()
                      .toLowerCase();
                  return role == wantedRole && status == 'approved';
                }).toList();

                docs.sort((a, b) {
                  final aFollowers = (a.data()['followersCount'] ?? 0) as int;
                  final bFollowers = (b.data()['followersCount'] ?? 0) as int;
                  if (aFollowers != bFollowers) {
                    return bFollowers.compareTo(aFollowers);
                  }
                  return _fullName(a.data()).compareTo(_fullName(b.data()));
                });

                final filtered = docs
                    .where((doc) => _matches(doc.data()))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _mode == _DirectoryMode.chef
                          ? 'Aramana uygun şef bulunamadı.'
                          : 'Aramana uygun diyetisyen bulunamadı.',
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final doc = filtered[i];
                    final data = doc.data();
                    final name = _fullName(data);
                    final photoUrl = (data['photoUrl'] ?? '').toString();
                    final followers = (data['followersCount'] ?? 0) as int;
                    final email = (data['email'] ?? '').toString().trim();
                    final subtitle = [
                      _mode == _DirectoryMode.chef
                          ? 'Onaylı şef'
                          : 'Onaylı diyetisyen',
                      if (email.isNotEmpty) email,
                    ].join(' - ');

                    return StreamBuilder<bool>(
                      stream: _followService.isFollowing(doc.id),
                      builder: (context, snap) {
                        final isFollowing = snap.data ?? false;

                        return ChefCard(
                          name: name,
                          photoUrl: photoUrl,
                          followersCount: followers,
                          subtitle: subtitle,
                          isFollowing: isFollowing,
                          onFollowTap: () async {
                            try {
                              if (isFollowing) {
                                await _followService.unfollow(doc.id);
                              } else {
                                await _followService.follow(doc.id);
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Islem basarisiz: $e')),
                              );
                            }
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _mode == _DirectoryMode.chef
                                    ? ChefProfilePage(chefId: doc.id)
                                    : DietitianProfilePage(dietitianId: doc.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8F6F1) : const Color(0xFFFFF1E8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFF00897B)
                    : const Color(0xFFE65F5C),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
