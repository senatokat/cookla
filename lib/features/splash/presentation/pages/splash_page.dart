import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';

import 'package:flutter_application_1/features/auth/presentation/pages/welcome/welcome_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/register/verify_email_page.dart';
import 'package:flutter_application_1/rolegate/role_gate_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    try {
      final user = _auth.currentUser;

      if (user == null) {
        _go(const WelcomePage());
        return;
      }

      final verified = await _auth.refreshAndCheckVerified();
      if (!mounted) return;

      if (!verified) {
        _go(const VerifyEmailPage());
        return;
      }

      _go(const RoleGatePage());
    } catch (_) {
      if (!mounted) return;
      _go(const WelcomePage());
    }
  }

  void _go(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
