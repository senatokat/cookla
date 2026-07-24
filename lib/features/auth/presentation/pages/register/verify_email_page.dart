import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';

import 'package:flutter_application_1/features/auth/presentation/pages/welcome/welcome_page.dart';
import 'package:flutter_application_1/shared/widgets/primary_button.dart';
import 'package:flutter_application_1/rolegate/role_gate_page.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _auth = AuthService();

  bool _resending = false;
  bool _checking = false;
  bool _leaving = false;

  bool get _busy => _resending || _checking || _leaving;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _resendMail() async {
    if (_busy) return;
    setState(() => _resending = true);

    try {
      await _auth.resendVerification();
      _snack("Doğrulama maili tekrar gönderildi");
    } catch (_) {
      _snack("Mail gönderilemedi. Tekrar dene.");
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _checkVerified() async {
    if (_busy) return;
    setState(() => _checking = true);

    try {
      final ok = await _auth.refreshAndCheckVerified();
      if (!mounted) return;

      if (!ok) {
        _snack(
          "Henüz doğrulanmadı. Maildeki linke tıkla ve tekrar kontrol et.",
        );
        return;
      }

      _snack("Mail doğrulandı");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleGatePage()),
      );
    } catch (_) {
      _snack("Kontrol sırasında hata oluştu.");
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _leaveVerification() async {
    if (_busy) return;
    setState(() => _leaving = true);

    try {
      await _auth.signOut();
    } catch (_) {
      // Geri cikis, Firebase sign out hata verse bile ekrani bos birakmamali.
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveVerification();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _busy ? null : _leaveVerification,
          ),
          title: const Text(
            "Mail Doğrulama",
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 26),
                const Icon(Icons.verified_outlined, size: 64),
                const SizedBox(height: 14),
                const Text(
                  "Mail doğrulama tamamlandı mı?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Maildeki doğrulama linkine tıkladıysan şimdi kontrol edebilirsin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 18),

                TextButton(
                  onPressed: _busy ? null : _resendMail,
                  child: Text(
                    _resending
                        ? "Gönderiliyor..."
                        : "Doğrulama Mailini Tekrar Gönder",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),

                const SizedBox(height: 10),

                PrimaryButton(
                  text: _checking
                      ? "Kontrol ediliyor..."
                      : "Doğrulamayı Kontrol Et",
                  onPressed: _busy ? null : _checkVerified,
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _busy
                      ? null
                      : () =>
                            _snack("İpucu: Spam/Junk klasörünü de kontrol et."),
                  child: const Text(
                    "Mail gelmediyse?",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
