import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/shared/widgets/primary_button.dart';

import 'package:flutter_application_1/features/auth/presentation/pages/register/verify_email_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/welcome/welcome_page.dart';

class SignUpInfoPage extends StatefulWidget {
  const SignUpInfoPage({super.key});

  @override
  State<SignUpInfoPage> createState() => _SignUpInfoPageState();
}

class _SignUpInfoPageState extends State<SignUpInfoPage> {
  final _auth = AuthService();
  bool _loading = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _resendMail() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await _auth.resendVerification();
      _snack("Doğrulama maili tekrar gönderildi");
    } catch (_) {
      _snack("Mail gönderilemedi. Tekrar dene.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goVerify() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
    );
  }

  Future<void> _leaveInfo() async {
    if (_loading) return;
    setState(() => _loading = true);

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
        if (!didPop) _leaveInfo();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _loading ? null : _leaveInfo,
          ),
          title: const Text(
            "Bilgilendirme",
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
                const Icon(Icons.mark_email_read_outlined, size: 64),
                const SizedBox(height: 14),

                const Text(
                  "Mail adresinize doğrulama bağlantısı gönderdik.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Lütfen e-postanızı açıp doğrulama linkine tıklayın.\n"
                  "Ardından 'Doğrulamayı Kontrol Et' ekranından kontrol edin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: _loading ? null : _resendMail,
                  child: Text(
                    _loading
                        ? "Gönderiliyor..."
                        : "Doğrulama Mailini Tekrar Gönder",
                    style: const TextStyle(color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 10),

                PrimaryButton(
                  text: "Doğrulamayı Kontrol Et",
                  onPressed: _loading ? null : _goVerify,
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _loading
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
