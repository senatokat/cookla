import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RejectedPage extends StatelessWidget {
  const RejectedPage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Başvuru Reddedildi"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Başvurunuz reddedildi.",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text("Çıkış Yap"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
