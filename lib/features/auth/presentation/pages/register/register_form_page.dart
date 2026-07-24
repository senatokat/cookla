import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/core/roles.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/login/login_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/register/signup_info_page.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/shared/widgets/app_text_field.dart';
import 'package:flutter_application_1/shared/widgets/primary_button.dart';

class RegisterFormPage extends StatefulWidget {
  const RegisterFormPage({super.key});

  @override
  State<RegisterFormPage> createState() => _RegisterFormPageState();
}

class _RegisterFormPageState extends State<RegisterFormPage> {
  final _auth = AuthService();

  final _nameC = TextEditingController();
  final _surnameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _passAgainC = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _obscureAgain = true;
  String _role = AppRoles.user;

  @override
  void dispose() {
    _nameC.dispose();
    _surnameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _passAgainC.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _register() async {
    if (_loading) return;

    final name = _nameC.text.trim();
    final surname = _surnameC.text.trim();
    final email = _emailC.text.trim();
    final password = _passC.text;
    final passwordAgain = _passAgainC.text;

    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordAgain.isEmpty) {
      _snack('Lutfen tum alanlari doldürün.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _snack('Geçerli bir email adresi girin.');
      return;
    }

    if (password.length < 6) {
      _snack('Sifre en az 6 karakter olmali.');
      return;
    }

    if (password != passwordAgain) {
      _snack('Sifreler eslesmiyor.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.register(
        name: name,
        surname: surname,
        email: email,
        password: password,
        role: _role,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignUpInfoPage()),
      );
    } on FirebaseAuthException catch (e) {
      _snack(_authMessage(e));
    } on TimeoutException catch (e) {
      _snack(e.message ?? 'Kayıt isteği zaman aşımına uğradı.');
    } catch (_) {
      _snack('Kayıt sirasinda beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authMessage(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => 'Bu email adresi zaten kayıtli.',
      'invalid-email' => 'Email formati gecersiz.',
      'weak-password' => 'Sifre cok zayif.',
      'network-request-failed' => 'Internet baglantisini kontrol edin.',
      _ => e.message ?? 'Kayıt basarisiz: ${e.code}',
    };
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
        title: const Text('Kayıt Ol', style: TextStyle(color: Colors.black)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.restaurant_menu, size: 72, color: kPrimary),
              const SizedBox(height: 18),
              AppTextField(
                controller: _nameC,
                hintText: 'Ad',
                icon: Icons.person_outline,
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _surnameC,
                hintText: 'Soyad',
                icon: Icons.person_outline,
                enabled: !_loading,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _emailC,
                hintText: 'Email',
                icon: Icons.mail_outline,
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _passC,
                hintText: 'Sifre',
                icon: Icons.lock_outline,
                enabled: !_loading,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
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
              const SizedBox(height: 12),
              AppTextField(
                controller: _passAgainC,
                hintText: 'Sifre tekrar',
                icon: Icons.lock_outline,
                enabled: !_loading,
                obscureText: _obscureAgain,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _loading ? null : _register(),
                suffixIcon: IconButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _obscureAgain = !_obscureAgain),
                  icon: Icon(
                    _obscureAgain ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                items: const [
                  DropdownMenuItem(
                    value: AppRoles.user,
                    child: Text('Kullanıcı'),
                  ),
                  DropdownMenuItem(
                    value: AppRoles.student,
                    child: Text('Gastronomi ogrencisi'),
                  ),
                  DropdownMenuItem(
                    value: AppRoles.chef,
                    child: Text('Şef / egitmen'),
                  ),
                  DropdownMenuItem(
                    value: AppRoles.dietitian,
                    child: Text('Diyetisyen'),
                  ),
                ],
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _role = value!),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.badge_outlined),
                  filled: true,
                  fillColor: Colors.grey.withAlpha(20),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: _loading ? 'Kayıt oluşturuluyor...' : 'Kayıt Ol',
                loading: _loading,
                onPressed: _loading ? null : _register,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Zaten hesabın var mi? '),
                  GestureDetector(
                    onTap: _loading
                        ? null
                        : () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                    child: const Text(
                      'Giris yap',
                      style: TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
