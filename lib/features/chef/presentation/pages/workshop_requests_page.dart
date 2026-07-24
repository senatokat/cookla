import 'package:flutter/material.dart';

class WorkshopRequestsPage extends StatelessWidget {
  const WorkshopRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workshop Talepleri")),
      body: const Center(
        child: Text("Burada workshop katılım talepleri görünecek."),
      ),
    );
  }
}
