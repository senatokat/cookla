import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/presentation/pages/home_dashboard_tab.dart';

class DashboardTab extends StatelessWidget {
  final String? uid;

  const DashboardTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return HomeDashboardTab(uid: uid);
  }
}
