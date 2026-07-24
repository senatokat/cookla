import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/roles.dart';
import 'package:flutter_application_1/features/recipes/data/recipe_service.dart';

import 'admin_requests_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _tab = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      _AdminDashboardPage(onOpenRequests: () => setState(() => _tab = 1)),
      const AdminRequestsPage(),
      const _AdminSettingsPage(),
    ];
  }

  String _titleForTab(int tab) {
    switch (tab) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Onaylar';
      case 2:
        return 'Admin Ayarlari';
      default:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hideAppBar = _tab == 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: hideAppBar ? null : AppBar(title: Text(_titleForTab(_tab))),
      body: SafeArea(
        child: IndexedStack(index: _tab, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            label: 'Onaylar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardPage extends StatelessWidget {
  final VoidCallback onOpenRequests;

  const _AdminDashboardPage({required this.onOpenRequests});

  int _countUsersByStatus(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String status,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final role = AppRoles.normalize(data['role'], fallback: AppRoles.user);
      final normalizedStatus = AppUserStatus.normalize(
        data['status'],
        fallback: AppRoles.needsApproval(role)
            ? AppUserStatus.pending
            : AppUserStatus.approved,
      );

      return normalizedStatus == status && AppRoles.needsApproval(role);
    }).length;
  }

  int _countUsersByRole(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String role,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final normalizedRole = AppRoles.normalize(
        data['role'],
        fallback: AppRoles.user,
      );
      return normalizedRole == role;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnap) {
        final userDocs = usersSnap.data?.docs ?? const [];
        final pendingUsers = _countUsersByStatus(
          userDocs,
          AppUserStatus.pending,
        );
        final approvedUsers = _countUsersByStatus(
          userDocs,
          AppUserStatus.approved,
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('recipes')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, recipesSnap) {
            final pendingRecipes = recipesSnap.data?.docs.length ?? 0;
            final loading =
                usersSnap.connectionState == ConnectionState.waiting ||
                recipesSnap.connectionState == ConnectionState.waiting;

            if (usersSnap.hasError || recipesSnap.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Dashboard verileri yuklenemedi.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (loading) const LinearProgressIndicator(minHeight: 2),
                if (loading) const SizedBox(height: 14),
                _DashboardHero(
                  pendingUsers: pendingUsers,
                  pendingRecipes: pendingRecipes,
                  onOpenRequests: onOpenRequests,
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.55,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MetricTile(
                      icon: Icons.pending_actions_outlined,
                      title: 'Bekleyen Basvuru',
                      value: '$pendingUsers',
                      color: const Color(0xFFE65F5C),
                    ),
                    _MetricTile(
                      icon: Icons.verified_outlined,
                      title: 'Onaylı Hesap',
                      value: '$approvedUsers',
                      color: const Color(0xFF2E9E62),
                    ),
                    _MetricTile(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'Bekleyen Tarif',
                      value: '$pendingRecipes',
                      color: const Color(0xFF6C63FF),
                    ),
                    _MetricTile(
                      icon: Icons.health_and_safety_outlined,
                      title: 'Diyetisyen',
                      value:
                          '${_countUsersByRole(userDocs, AppRoles.dietitian)}',
                      color: const Color(0xFF00897B),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _RoleBreakdown(
                  chefCount: _countUsersByRole(userDocs, AppRoles.chef),
                  studentCount: _countUsersByRole(userDocs, AppRoles.student),
                  dietitianCount: _countUsersByRole(
                    userDocs,
                    AppRoles.dietitian,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final int pendingUsers;
  final int pendingRecipes;
  final VoidCallback onOpenRequests;

  const _DashboardHero({
    required this.pendingUsers,
    required this.pendingRecipes,
    required this.onOpenRequests,
  });

  @override
  Widget build(BuildContext context) {
    final totalPending = pendingUsers + pendingRecipes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0D7CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kontrol Merkezi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            totalPending == 0
                ? 'Şu anda kontrol bekleyen bir işlem yok.'
                : '$totalPending işlem kontrol bekliyor.',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onOpenRequests,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Basvurulari Yonet'),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBreakdown extends StatelessWidget {
  final int chefCount;
  final int studentCount;
  final int dietitianCount;

  const _RoleBreakdown({
    required this.chefCount,
    required this.studentCount,
    required this.dietitianCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profesyonel Roller',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _RoleLine(label: 'Şef / Ogretmen', value: chefCount),
          _RoleLine(label: 'Öğrenci', value: studentCount),
          _RoleLine(label: 'Diyetisyen', value: dietitianCount),
        ],
      ),
    );
  }
}

class _RoleLine extends StatelessWidget {
  final String label;
  final int value;

  const _RoleLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _AdminSettingsPage extends StatelessWidget {
  const _AdminSettingsPage();

  Future<void> _seedDefaultRecipes(BuildContext context) async {
    try {
      final count = await RecipeService().seedDefaultRecipesIfEmpty();
      if (!context.mounted) return;

      final message = count == 0
          ? 'Varsayılan tarifler zaten ekli.'
          : '$count varsayılan tarif eklendi.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0E3DB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Icerik Ayarlari',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Uygulama boş görünüyorsa varsayılan tarifleri buradan tek seferde ekleyebilirsin.',
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _seedDefaultRecipes(context),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Varsayılan Tarifleri Ekle'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
