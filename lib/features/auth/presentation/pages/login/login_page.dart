import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/shared/widgets/app_text_field.dart';
import 'package:flutter_application_1/shared/widgets/primary_button.dart';
import 'package:flutter_application_1/core/constants.dart';

import 'package:flutter_application_1/features/auth/presentation/pages/register/register_form_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/register/verify_email_page.dart';
import 'package:flutter_application_1/features/splash/presentation/pages/splash_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();

  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;

    if (email.isEmpty || pass.isEmpty) {
      _snack("Email ve şifre boş olamaz.");
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.login(email: email, password: pass);

      final verified = await _auth.refreshAndCheckVerified();
      if (!mounted) return;

      if (!verified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
        );
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'Bu email ile kullanıcı bulunamadı.',
        'wrong-password' => 'Şifre yanlış.',
        'invalid-email' => 'Email formatı geçersiz.',
        'too-many-requests' => 'Çok fazla deneme. Biraz sonra tekrar dene.',
        _ => 'Giriş başarısız: ${e.message ?? e.code}',
      };

      _snack(msg);
    } catch (_) {
      _snack("Beklenmeyen hata oluştu.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _loading ? null : () => Navigator.pop(context),
        ),
        title: const Text("Giriş Yap", style: TextStyle(color: Colors.black)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              AppTextField(
                controller: _emailC,
                hintText: "Email",
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              AppTextField(
                controller: _passC,
                hintText: "Şifre",
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _login(),
                suffixIcon: IconButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black54,
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => _snack("Şifre sıfırlama sonraki adım."),
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimary,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text("Şifremi Unuttum?"),
                ),
              ),

              const SizedBox(height: 8),

              PrimaryButton(
                text: _loading ? "Giriş yapılıyor..." : "Giriş Yap",
                loading:
                    _loading, // PrimaryButton içinde loading varsa güzel olur
                onPressed: _loading ? null : _login,
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Henüz hesabınız yok mu? "),
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterFormPage(),
                              ),
                            ),
                      child: const Text(
                        "Kayıt ol",
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
