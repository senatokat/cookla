import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/features/home/presentation/tabs/chefs_tab.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter_application_1/features/workshops/presentation/pages/workshops_tab.dart';
import 'package:flutter_application_1/features/recipes/presentation/pages/recipes_tab.dart';
import '../tabs/dashboard_tab.dart';
import '../tabs/profile_tab.dart';
import '../widgets/bottom_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = AuthService();
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    final tabs = <Widget>[
      DashboardTab(uid: user?.uid),
      WorkshopsTab(uid: user?.uid),
      RecipesTab(),
      const ChefsTab(),
      ProfileTab(
        uid: user?.uid,
        email: user?.email ?? "-",
        onLogout: () async {
          await _auth.signOut();
          if (!context.mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashPage()),
            (route) => false,
          );
        },
      ),
    ];

    final safeIndex = _tab.clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: tabs[safeIndex],
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}
