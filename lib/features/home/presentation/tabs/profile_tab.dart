import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/roles.dart';
import 'package:flutter_application_1/core/text_formatters.dart';
import 'package:flutter_application_1/features/admin/presentation/pages/admin_shell_page.dart';
import 'package:flutter_application_1/features/diet_plans/presentation/pages/weekly_diet_plans_page.dart';
import 'package:flutter_application_1/features/home/presentation/pages/ingredient_manager_page.dart';
import 'package:flutter_application_1/features/home/presentation/pages/shopping_list_page.dart';
import 'package:flutter_application_1/features/recipes/data/recipe_service.dart';
import 'package:flutter_application_1/features/recipes/presentation/pages/pending_recipes_page.dart';
import 'package:flutter_application_1/features/recipes/presentation/pages/recipe_collection_page.dart';
import 'package:flutter_application_1/features/workshops/models/workshop.dart';
import 'package:flutter_application_1/services/role_service.dart';
import 'package:flutter_application_1/services/workshop_service.dart';

class ProfileTab extends StatelessWidget {
  final String? uid;
  final String email;
  final Future<void> Function() onLogout;

  const ProfileTab({
    super.key,
    required this.uid,
    required this.email,
    required this.onLogout,
  });

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  String _fullName(Map<String, dynamic>? data) {
    final name = (data?['name'] ?? '').toString().trim();
    final surname = (data?['surname'] ?? '').toString().trim();
    return AppTextFormatters.displayName([
      name,
      surname,
    ], fallback: 'Kullanıcı');
  }

  String _roleLabel(String role) {
    switch (role) {
      case AppRoles.chef:
        return 'Şef';
      case AppRoles.student:
        return 'Öğrenci';
      case AppRoles.dietitian:
        return 'Diyetisyen';
      case AppRoles.admin:
        return 'Admin';
      default:
        return 'Kullanıcı';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppUserStatus.approved:
        return 'Onaylı';
      case AppUserStatus.rejected:
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case AppUserStatus.approved:
        return Colors.green;
      case AppUserStatus.rejected:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _openSavedRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeCollectionPage(
          title: 'Kaydedilen Tarifler',
          emptyText: 'Henüz kaydettigin tarif yok.',
          stream: RecipeService().streamSavedRecipes(),
        ),
      ),
    );
  }

  void _openLikedRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeCollectionPage(
          title: 'Beğenilen Tarifler',
          emptyText: 'Henüz begendigin tarif yok.',
          stream: RecipeService().streamLikedRecipes(),
        ),
      ),
    );
  }

  void _openSavedDietPlans(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyDietPlansPage(manageOwn: false, savedOnly: true),
      ),
    );
  }

  void _openIngredientManager(BuildContext context) {
    if (uid == null || uid!.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IngredientManagerPage(uid: uid!)),
    );
  }

  void _openShoppingList(BuildContext context) {
    if (uid == null || uid!.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShoppingListPage(uid: uid!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final emailFromFirebase = (user?.email ?? email).trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (uid == null || uid!.isEmpty)
            _ProfileHeader(
              name: 'Kullanıcı',
              email: emailFromFirebase,
              followers: 0,
              following: 0,
              roleLabel: 'Kullanıcı',
              statusLabel: 'Beklemede',
              statusColor: Colors.orange,
            )
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userStream(uid!),
              builder: (context, userSnap) {
                final data = userSnap.data?.data() ?? {};
                final followers = (data['followersCount'] ?? 0) as int;
                final following = (data['followingCount'] ?? 0) as int;
                final normalizedRole = AppRoles.normalize(
                  data['role'],
                  fallback: AppRoles.user,
                );
                final normalizedStatus = AppUserStatus.normalize(
                  data['status'],
                  fallback: AppRoles.needsApproval(normalizedRole)
                      ? AppUserStatus.pending
                      : AppUserStatus.approved,
                );

                return _ProfileHeader(
                  name: _fullName(data),
                  email: emailFromFirebase,
                  followers: followers,
                  following: following,
                  roleLabel: _roleLabel(normalizedRole),
                  statusLabel: _statusLabel(normalizedStatus),
                  statusColor: _statusColor(normalizedStatus),
                );
              },
            ),
          const SizedBox(height: 14),
          _CardTile(
            leading: Icons.bookmark_border,
            title: 'Kaydedilenler',
            subtitle: 'Kaydettiğin tarifleri gör',
            onTap: () => _openSavedRecipes(context),
          ),
          const SizedBox(height: 12),
          _CardTile(
            leading: Icons.favorite_border,
            title: 'Beğenilenler',
            subtitle: 'Beğendiğin tarifleri gör',
            onTap: () => _openLikedRecipes(context),
          ),
          const SizedBox(height: 12),
          _CardTile(
            leading: Icons.health_and_safety_outlined,
            title: 'Kaydettigim Diyetler',
            subtitle: 'Kaydettiğin haftalık diyet programlarını gör',
            onTap: () => _openSavedDietPlans(context),
          ),
          const SizedBox(height: 12),
          _CardTile(
            leading: Icons.kitchen_outlined,
            title: 'Malzemelerim',
            subtitle: 'Evde olan malzemeleri seç veya yeni malzeme ekle',
            onTap: () => _openIngredientManager(context),
          ),
          const SizedBox(height: 12),
          _CardTile(
            leading: Icons.shopping_basket_outlined,
            title: 'Alışveriş Listem',
            subtitle: 'Home ekranindan kaydettigin listeyi yönet',
            onTap: () => _openShoppingList(context),
          ),
          if (uid != null && uid!.isNotEmpty) ...[
            const SizedBox(height: 12),
            StreamBuilder<RoleInfo>(
              stream: RoleService().watchRoleInfo(uid!),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox.shrink();
                }

                final info = snap.data!;
                final isApproved = info.isApproved;
                final canManageRecipes =
                    (info.isChef || info.isAdmin) && isApproved;
                final canManageDietPlans = info.isDietitian && isApproved;
                final canViewDietPlans = isApproved && !canManageDietPlans;

                return Column(
                  children: [
                    if (canViewDietPlans) ...[
                      _CardTile(
                        leading: Icons.health_and_safety_outlined,
                        title: 'Yayınlanan Diyet Programlari',
                        subtitle: 'Diyetisyenlerin haftalık programlarını gör',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const WeeklyDietPlansPage(manageOwn: false),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (canManageRecipes) ...[
                      _CardTile(
                        leading: Icons.pending_actions,
                        title: 'Onay Bekleyen Tarifler',
                        subtitle: 'Bekleyen tarifleri onayla veya reddet',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PendingRecipesPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (canManageDietPlans) ...[
                      _CardTile(
                        leading: Icons.calendar_month_outlined,
                        title: 'Haftalik Diyet Programlari',
                        subtitle: 'Yayındaki şef tariflerinden program oluştur',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WeeklyDietPlansPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (info.isAdmin && isApproved) ...[
                      _CardTile(
                        leading: Icons.admin_panel_settings,
                        title: 'Admin Panel',
                        subtitle: 'Kullanıcı onaylarını yönet',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminGuard(
                                uid: uid!,
                                child: const AdminShellPage(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (!isApproved) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                          color: Colors.black12,
                        ),
                        child: Text(
                          'Hesap durumu: ${_statusLabel(info.status)}\nOnay tamamlanmadan yönetim panelleri gorunmez.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const _WorkshopInviteSection(),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async => onLogout(),
              icon: const Icon(Icons.logout),
              label: const Text('Cikis Yap'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final int followers;
  final int following;
  final String roleLabel;
  final String statusLabel;
  final Color statusColor;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.followers,
    required this.following,
    required this.roleLabel,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0x11000000),
            child: Icon(Icons.person_outline, color: Colors.black54),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(
                      text: roleLabel,
                      backgroundColor: const Color(0xFFFFF1EC),
                      foregroundColor: const Color(0xFFE65F5C),
                    ),
                    _MiniChip(
                      text: statusLabel,
                      backgroundColor: statusColor.withAlpha(20),
                      foregroundColor: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$followers takipci   •   $following takip edilen',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  const _MiniChip({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CardTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        leading: Icon(leading),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _WorkshopInviteSection extends StatelessWidget {
  const _WorkshopInviteSection();

  @override
  Widget build(BuildContext context) {
    final service = WorkshopService();

    return StreamBuilder<List<Workshop>>(
      stream: service.streamPendingCoChefInvites(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workshop Davetleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...items.map((item) {
              final workshop = item;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${workshop.chefName} seni ortak şef olarak davet etti.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              try {
                                await service.rejectCoChefInvite(workshop.id);
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hata: $error')),
                                );
                              }
                            },
                            child: const Text('Reddet'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await service.acceptCoChefInvite(workshop.id);
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hata: $error')),
                                );
                              }
                            },
                            child: const Text('Kabul Et'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class AdminGuard extends StatelessWidget {
  final String uid;
  final Widget child;

  const AdminGuard({super.key, required this.uid, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RoleInfo>(
      future: RoleService().getRoleInfo(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return const _NotAllowed(msg: 'Bir hata oluştu.');
        }

        final info = snap.data!;
        final ok = info.isAdmin && info.isApproved;

        if (!ok) {
          return const _NotAllowed(msg: 'Bu sayfaya erişim yetkiniz yok.');
        }

        return child;
      },
    );
  }
}

class _NotAllowed extends StatelessWidget {
  final String msg;

  const _NotAllowed({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erişim Yok')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(msg, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
