import 'package:flutter/material.dart';

class WaitingApprovalPage extends StatelessWidget {
  const WaitingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Onay Bekleniyor")),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Başvurunuz inceleniyor.\nAdmin onayladıktan sonra uygulamayı kullanabilirsiniz.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
