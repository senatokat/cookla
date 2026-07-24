import 'package:flutter/material.dart';

class ChefWorkshopsPage extends StatelessWidget {
  const ChefWorkshopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workshop Yönetimi")),
      body: const Center(
        child: Text(
          "Buraya workshop oluşturma ve talepleri yönetme ekranları gelecek.",
        ),
      ),
    );
  }
}
