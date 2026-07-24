import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'package:flutter_application_1/features/splash/presentation/pages/splash_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: buildAppTheme(),

      home: const SplashPage(),
    );
  }
}
