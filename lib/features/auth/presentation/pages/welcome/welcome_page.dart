import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/shared/widgets/primary_button.dart';

import 'package:flutter_application_1/features/auth/presentation/pages/login/login_page.dart';
import 'package:flutter_application_1/features/auth/presentation/pages/register/register_form_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 110, color: kPrimary),
              const SizedBox(height: 24),

              const Text(
                "COOKLA",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                "Size özel tarif önerileri için hemen hesap oluşturun veya giriş yapın.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: "Hesap Oluştur",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterFormPage()),
                ),
              ),
              const SizedBox(height: 14),

              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kPrimary),
                  foregroundColor: kPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Giriş Yap"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
